#!/usr/bin/env ruby
# frozen_string_literal: true
require 'bundler/setup'
require 'rails'
require 'action_controller/railtie'
require 'kamiliff'
require 'rack/mock'
require 'tmpdir'
require 'json'

# A complete host boot is isolated from other Rails test applications.
Dir.mktmpdir('kamiliff-sdk-host-') do |directory|
  host = Class.new(Rails::Application) do
    config.eager_load = false
    config.secret_key_base = 'local-sdk-acceptance-only' * 4
    config.hosts.clear
    config.logger = Logger.new(File::NULL)
  end
  host.config.root = directory
  host.initialize!
  request = Rack::MockRequest.new(host)
  response = request.get('/kamiliff/sdk.js')
  abort "SDK status #{response.status}" unless response.status == 200
  abort 'SDK body missing' unless response.body == File.binread(Kamiliff::Engine.root.join('app/assets/javascripts/kamiliff.js'))
  abort 'Wrong content type' unless response['content-type'].include?('javascript')
  abort 'Missing public cache' unless response['cache-control'] == 'max-age=300, public'
  revalidated = request.get('/kamiliff/sdk.js', 'HTTP_IF_NONE_MATCH' => response['etag'])
  abort "Revalidation status #{revalidated.status}" unless revalidated.status == 304
  abort 'Revalidation body not empty' unless revalidated.body.empty?
  puts JSON.generate(status: response.status, revalidated: revalidated.status, assets_configured: host.config.respond_to?(:assets))
end
