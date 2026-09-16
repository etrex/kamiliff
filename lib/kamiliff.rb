# frozen_string_literal: true
require 'rails'
require 'kamiliff/engine'
require 'kamiliff/version'
require 'kamiliff/services/base64_encode_service'
require 'kamiliff/services/base64_decode_service'
require 'kamiliff/services/liff_service'
require 'kamiliff/id_token_verifier'
require 'kamiliff/application'

module Kamiliff
  class << self
    def applications
      @applications ||= {}.freeze
    end

    def register_application(name, **configuration)
      raise ArgumentError, 'invalid application name' unless Application::NAME.match?(name.to_s)
      application = Application.new(**configuration)
      @applications = applications.merge(name.to_s => application).freeze
      application
    end

    def application(name)
      applications.fetch(name.to_s)
    end

    def entries
      @entries ||= {}.freeze
    end

    # Call during application initialization. Callbacks are trusted server code;
    # user input can select an existing name but cannot create a route or method.
    def register_entry(name, &handler)
      raise ArgumentError, 'entry handler required' unless handler
      raise ArgumentError, 'invalid entry name' unless /\A[a-z][a-z0-9_]*\z/.match?(name.to_s)
      @entries = entries.merge(name.to_s => handler).freeze
    end

    def setup
      yield self
    end
  end
end
