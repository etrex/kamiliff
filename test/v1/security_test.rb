# frozen_string_literal: true
require 'minitest/autorun'
require 'action_controller/railtie'
require 'rack/mock'
require_relative '../../lib/kamiliff'
require_relative '../../app/controllers/liff_controller'

class KamiliffSecurityTest < Minitest::Test
  def claims
    { 'iss' => 'https://access.line.me', 'aud' => 'channel-1', 'sub' => 'real-user', 'exp' => 200, 'nonce' => 'server-nonce' }
  end

  def verifier(values = claims)
    client = Object.new
    client.define_singleton_method(:verify_id_token) do |id_token:, client_id:|
      raise 'wrong request' unless id_token == 'opaque-token' && client_id == 'channel-1'
      values
    end
    Kamiliff::IdTokenVerifier.new(client: client, client_id: 'channel-1', clock: -> { 100 })
  end

  def test_verifier_returns_only_validated_identity_not_group_context
    identity = verifier.verify(id_token: 'opaque-token', expected_nonce: 'server-nonce')
    assert_equal 'real-user', identity.subject
    refute_respond_to identity, :group_id
    assert_raises(FrozenError) { identity.subject.replace('forged') }
  end

  def test_rejects_invalid_claims_and_nonce
    [{ 'iss' => 'evil' }, { 'aud' => 'wrong' }, { 'sub' => '' }, { 'exp' => 100 }, { 'exp' => '200' }].each do |override|
      assert_raises(Kamiliff::VerificationFailed) { verifier(claims.merge(override)).verify(id_token: 'opaque-token') }
    end
    assert_raises(Kamiliff::VerificationFailed) { verifier.verify(id_token: 'opaque-token', expected_nonce: 'wrong') }
    assert_raises(Kamiliff::VerificationFailed) { verifier.verify(id_token: '') }
  end

  def test_unknown_entry_and_legacy_route_never_dispatch_path
    status, = LiffController.action(:entry).call(Rack::MockRequest.env_for('/liff_entry?path=/admin&_method=DELETE'))
    assert_equal 404, status
    # Use GET only to inspect the removed action; the actual route permits POST
    # and additionally has normal Rails CSRF protection.
    status, = LiffController.action(:route).call(Rack::MockRequest.env_for('/liff_route?path=/admin&_method=DELETE'))
    assert_equal 410, status
  end

  def test_only_registered_callback_runs
    Kamiliff.register_entry('test_entry') { |controller| controller.render plain: 'explicit entry' }
    status, _, body = LiffController.action(:entry).call(Rack::MockRequest.env_for('/liff_entry?entry=test_entry&path=/admin&_method=DELETE'))
    assert_equal 200, status
    assert_equal 'explicit entry', body.body
  end

  def test_helper_rejects_route_as_entry
    assert_raises(ArgumentError) { LiffService.new(entry: '/admin?_method=DELETE') }
  end
end
