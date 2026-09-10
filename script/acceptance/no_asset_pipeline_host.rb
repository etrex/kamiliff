#!/usr/bin/env ruby
# frozen_string_literal: true

require "tmpdir"
require "open3"
require "json"
require "rbconfig"

root = File.expand_path("../..", __dir__)
bundle = File.join(root, "Gemfile")

Dir.mktmpdir("kamiliff-no-assets-", "/tmp") do |directory|
  host = File.join(directory, "host")
  environment = {
    "BUNDLE_GEMFILE" => bundle,
    "RAILS_ENV" => "development"
  }
  create = [
    RbConfig.ruby, "-S", "bundle", "exec", "rails", "new", host,
    "--skip-bundle",
    "--skip-git",
    "--skip-test",
    "--skip-system-test",
    "--skip-javascript",
    "--skip-asset-pipeline",
    "--skip-active-record",
    "--skip-action-mailer",
    "--skip-action-mailbox",
    "--skip-action-text",
    "--skip-active-storage",
    "--skip-solid",
    "--skip-bootsnap"
  ]

  output, status = Open3.capture2e(environment, *create, chdir: directory)
  abort output unless status.success?

  expression = "puts JSON.generate(engine: Kamiliff::Engine.engine_name, assets_configured: Rails.application.config.respond_to?(:assets))"
  output, status = Open3.capture2e(environment, RbConfig.ruby, File.join(host, "bin/rails"), "runner", expression, chdir: host)
  abort output unless status.success?

  result = JSON.parse(output.lines.last)
  abort result.inspect unless result == { "engine" => "kamiliff_engine", "assets_configured" => false }
  puts JSON.generate(result.merge("booted" => true))
end
