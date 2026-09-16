# frozen_string_literal: true
require 'minitest/autorun'
require_relative '../../lib/kamiliff'

class ApplicationNavigationTest < Minitest::Test
  # KAMILIFF-NAV-001: docs/acceptance/application_navigation.md
  def test_primary_secondary_links_and_immutable_configuration
    app = Kamiliff::Application.new(liff_id: '123-abc', endpoint_path: '/catalog', parameters: %i[page group])
    assert_equal 'https://liff.line.me/123-abc?page=ranking&group=123', app.url(page: 'ranking', group: '123')
    assert_equal '/catalog?page=ranking', app.entry_path(page: 'ranking')
    assert_equal({ 'page' => 'ranking', 'group' => '123' }, app.parse('liff.state=%3Fpage%3Dranking%26group%3D123&code=oauth'))
    assert_equal({ 'page' => 'ranking' }, app.parse('page=ranking&code=oauth&state=nonce'))
    assert_equal 'https://liff.line.me/123-abc?page=ranking', app.url(page: 'ranking', group: nil)
    assert_raises(ArgumentError) { app.url(unknown: nil) }
    assert app.frozen?
    assert app.parameters.frozen?
    assert app.parameters.all?(&:frozen?)
    assert app.parse('page=ranking').values.all?(&:frozen?)
  end

  # KAMILIFF-NAV-002: same hostile raw query requests as manual execution.
  def test_rejects_ambiguous_nested_or_malformed_navigation
    app = Kamiliff::Application.new(liff_id: '123-abc', endpoint_path: '/catalog', parameters: %i[page group])
    ['page=a&page=b', 'liff.state=%3Fpath%3D%2Fadmin', 'page=a&liff.state=%3Fpage%3Db',
     'group%5B%5D=1', 'page=%FF', 'page=%', 'liff.state=%2Fadmin', "page=#{'x' * 2049}"].each do |query|
      assert_raises(ArgumentError, query.byteslice(0, 100)) { app.parse(query) }
    end
    assert_raises(ArgumentError) { app.url(page: []) }
    assert_raises(ArgumentError) { Kamiliff::Application.new(liff_id: '123-abc', endpoint_path: '//evil.test', parameters: []) }
  end

  def test_percent_encoding_expansion_round_trips
    app = Kamiliff::Application.new(liff_id: 'test-liff', endpoint_path: '/catalog', parameters: [:page])
    text = '%' * 2048
    query = URI.encode_www_form('liff.state' => '?' + URI.encode_www_form(page: text))
    assert_equal text, app.parse(query).fetch('page')
  end

  def test_registry_keeps_server_owned_application_objects
    registered = Kamiliff.register_application(:manual_catalog, liff_id: '123-abc', endpoint_path: '/catalog', parameters: %i[page group])
    assert_same registered, Kamiliff.application(:manual_catalog)
    assert Kamiliff.applications.frozen?
  end
end
