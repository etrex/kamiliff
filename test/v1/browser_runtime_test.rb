require 'minitest/autorun'
require 'open3'

class BrowserRuntimeTest < Minitest::Test
  def test_browser_runtime_contracts
    root = File.expand_path('../..', __dir__)
    output, status = Open3.capture2e('node', '--test', *Dir[File.join(root, 'test/browser/*.test.cjs')])
    assert status.success?, output
  end
end
