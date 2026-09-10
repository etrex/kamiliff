# frozen_string_literal: true
require 'uri'
class LiffService
  attr_reader :entry, :size, :url, :id

  def initialize(options)
    @entry = options.fetch(:entry).to_s
    raise ArgumentError, 'invalid entry name' unless /\A[a-z][a-z0-9_]*\z/.match?(@entry)
    @size = options.fetch(:liff_size, :compact).to_s.upcase
    raise ArgumentError, 'invalid LIFF size' unless %w[COMPACT TALL FULL].include?(@size)
    @url = ENV.fetch("LIFF_#{@size}")
    uri = URI.parse(@url)
    raise ArgumentError, 'expected https://liff.line.me/<id>' unless uri.scheme == 'https' && uri.host == 'liff.line.me' && !uri.userinfo && !uri.query && !uri.fragment && uri.path.match?(%r{\A/[^/]+\z})
    @id = uri.path.delete_prefix('/')
  end

  def full_url
    "#{url}?#{URI.encode_www_form(entry: entry)}"
  end
end
