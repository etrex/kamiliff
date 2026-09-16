# frozen_string_literal: true
require 'uri'

module Kamiliff
  # Navigation is public input, never identity or authorization evidence.
  class Application
    MAX_QUERY_BYTES = 8192
    MAX_WIRE_QUERY_BYTES = 32768
    MAX_VALUE_BYTES = 2048
    NAME = /\A[a-z][a-z0-9_]{0,63}\z/
    RESERVED = %w[liff state code error error_description scope liffClientId liffRedirectUri].freeze
    attr_reader :liff_id, :endpoint_path, :parameters

    def initialize(liff_id:, endpoint_path:, parameters: [])
      raise ArgumentError, 'invalid LIFF ID' unless liff_id.is_a?(String) && /\A[A-Za-z0-9_-]{1,128}\z/.match?(liff_id)
      unless endpoint_path.is_a?(String) && %r{\A/(?:[A-Za-z0-9_-]+/)*[A-Za-z0-9_-]*\z}.match?(endpoint_path)
        raise ArgumentError, 'endpoint must be an absolute local path'
      end
      names = parameters.map(&:to_s)
      unless names.uniq == names && names.all? { |name| NAME.match?(name) && !RESERVED.include?(name) }
        raise ArgumentError, 'invalid navigation parameter names'
      end
      @liff_id = liff_id.dup.freeze
      @endpoint_path = endpoint_path.dup.freeze
      @parameters = names.map { |name| name.dup.freeze }.freeze
      freeze
    end

    def url(**params)
      with_query("https://liff.line.me/#{liff_id}", normalize(params))
    end

    def entry_path(**params)
      with_query(endpoint_path, normalize(params))
    end

    # Accept the SDK primary redirect (?liff.state=%3F...) and secondary
    # redirect. Never reinterpret a caller-provided path as a Rails route.
    def parse(query_string)
      direct = decode(query_string, limit: MAX_WIRE_QUERY_BYTES)
      if direct.keys.any? { |key| parameters.any? { |name| key.start_with?("#{name}[") } }
        raise ArgumentError, 'navigation values must be scalar'
      end
      state = direct.delete('liff.state')
      navigation = direct.select { |key, _| parameters.include?(key) }
      if state && !state.empty?
        raise ArgumentError, 'invalid LIFF state' unless state.start_with?('?')
        nested = decode(state.delete_prefix('?'))
        raise ArgumentError, 'unknown LIFF state parameter' unless (nested.keys - parameters).empty?
        raise ArgumentError, 'conflicting navigation parameters' unless (navigation.keys & nested.keys).empty?
        navigation.merge!(nested)
      end
      normalize(navigation)
    end

    private

    def normalize(params)
      result = {}
      params.each do |key, value|
        name = key.to_s
        raise ArgumentError, 'unknown navigation parameter' unless parameters.include?(name)
        raise ArgumentError, 'duplicate navigation parameter' if result.key?(name)
        next if value.nil?
        unless value.is_a?(String) || value.is_a?(Integer) || value == true || value == false
          raise ArgumentError, 'navigation values must be scalar'
        end
        text = value.to_s
        unless text.valid_encoding? && text.bytesize <= MAX_VALUE_BYTES && !text.match?(/[\x00-\x1f\x7f]/)
          raise ArgumentError, 'invalid navigation value'
        end
        result[name.dup.freeze] = text.dup.freeze
      end
      raise ArgumentError, 'navigation query too long' if URI.encode_www_form(result).bytesize > MAX_QUERY_BYTES
      result.freeze
    end

    def decode(query, limit: MAX_QUERY_BYTES)
      raise ArgumentError, 'invalid query' unless query.is_a?(String) && query.bytesize <= limit && query.valid_encoding?
      raise ArgumentError, 'invalid query escape' if query.match?(/%(?![0-9a-fA-F]{2})/)
      query.split('&', -1).reject(&:empty?).map do |pair|
        pair.split('=', 2).then do |key, value|
          [key, value || ''].map do |part|
            text = URI.decode_www_form_component(part, Encoding::UTF_8)
            raise ArgumentError, 'invalid query encoding' unless text.valid_encoding?
            text
          end
        end
      end.each_with_object({}) do |(key, value), result|
        raise ArgumentError, 'duplicate query parameter' if result.key?(key)
        result[key] = value
      end
    end

    def with_query(path, params)
      params.empty? ? path : "#{path}?#{URI.encode_www_form(params)}"
    end
  end
end
