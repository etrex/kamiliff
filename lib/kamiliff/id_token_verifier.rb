# frozen_string_literal: true
module Kamiliff
  class VerificationFailed < StandardError; end
  VerifiedIdentity = Data.define(:issuer, :audience, :subject, :expires_at)

  class IdTokenVerifier
    ISSUER = 'https://access.line.me'
    def initialize(client:, client_id:, clock: -> { Time.now.to_i })
      raise ArgumentError, 'client_id required' if client_id.to_s.empty?
      @client, @client_id, @clock = client, client_id.to_s.dup.freeze, clock
    end

    # client must call LINE's server-side verification endpoint over HTTPS, use
    # bounded timeouts, and reject non-success HTTP responses. Never pass a local
    # JWT decode-only implementation or browser-returned claims as this client.
    def verify(id_token:, expected_nonce: nil)
      raise VerificationFailed, 'missing or oversized token' unless id_token.is_a?(String) && id_token.bytesize.between?(1, 16_384)
      claims = @client.verify_id_token(id_token: id_token, client_id: @client_id)
      valid = claims.is_a?(Hash) && claims['iss'] == ISSUER && claims['aud'] == @client_id &&
        claims['sub'].is_a?(String) && !claims['sub'].empty? &&
        claims['exp'].is_a?(Integer) && claims['exp'] > @clock.call &&
        (expected_nonce.nil? || (expected_nonce.is_a?(String) && !expected_nonce.empty? && claims['nonce'] == expected_nonce))
      raise VerificationFailed, 'invalid identity token' unless valid
      VerifiedIdentity.new(issuer: ISSUER, audience: @client_id.dup.freeze,
        subject: claims['sub'].dup.freeze, expires_at: claims['exp'])
    end
  end
end
