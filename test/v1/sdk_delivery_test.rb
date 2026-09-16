# frozen_string_literal: true
require 'minitest/autorun'
require 'open3'
require 'json'
require 'rbconfig'

class SdkDeliveryTest < Minitest::Test
  # KAMILIFF-SDK-001: replays the manually exercised complete host Rack request.
  def test_public_sdk_delivery_and_conditional_get_without_asset_pipeline
    root = File.expand_path('../..', __dir__)
    output, status = Open3.capture2e(RbConfig.ruby, '-Ilib', 'script/acceptance/sdk_delivery.rb', chdir: root)
    assert status.success?, output
    assert_equal({ 'status' => 200, 'revalidated' => 304, 'assets_configured' => false }, JSON.parse(output.lines.last))
  end
end
