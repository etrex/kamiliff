# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "json"
require "rbconfig"

class NoAssetPipelineHostTest < Minitest::Test
  # KAMILIFF-HOST-001 repeats docs/acceptance/no_asset_pipeline_host.md by
  # executing the exact same fresh-host acceptance program.
  def test_fresh_rails_host_without_asset_pipeline_loads_kamiliff
    root = File.expand_path("../..", __dir__)
    output, status = Open3.capture2e(
      RbConfig.ruby,
      File.join(root, "script/acceptance/no_asset_pipeline_host.rb"),
      chdir: root
    )

    assert status.success?, output
    assert_equal(
      { "engine" => "kamiliff_engine", "assets_configured" => false, "booted" => true },
      JSON.parse(output.lines.last)
    )
  end
end
