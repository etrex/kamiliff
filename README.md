# Kamiliff 1.0

Rails LIFF view and verified-identity integration. **Breaking rewrite:** old
request forwarding and automatic form-to-chat commands are removed.

## Explicit application entries

Configure a LIFF endpoint on your host application. Register server-owned entry
names during initialization; no submitted Rails path or HTTP method is executed:

```ruby
Kamiliff.register_entry('warehouse') do |controller|
  # Render a host-owned LIFF bootstrap page. Its subsequent authenticated actions
  # use normal Rails routes, CSRF, authorization, and database transactions.
  controller.render template: 'warehouse/entry'
end
```

Use `liff_path(entry: 'warehouse', liff_size: :compact)` with `LIFF_COMPACT`,
`LIFF_TALL`, or `LIFF_FULL` set to `https://liff.line.me/<LIFF-ID>`.
Unknown entries return 404. The legacy `/liff_route` action returns 410.

The host must initialize its supported LIFF SDK version and handle the documented
LIFF redirect/bootstrap lifecycle. Kamiliff no longer injects jQuery, Bootstrap,
a dated SDK, or intercepts forms. Use ordinary Rails/Hotwire forms and explicit
Stimulus actions. The minimal `liff` layout exposes a `:head` content slot.
The send/share partials accept structured message hashes only and safely embed
JSON; they are explicit user-flow helpers, not default background actions.

## Verify identity on the server

```ruby
verifier = Kamiliff::IdTokenVerifier.new(
  client: line_verification_client, client_id: ENV.fetch('LINE_LOGIN_CHANNEL_ID')
)
identity = verifier.verify(id_token: submitted_token, expected_nonce: server_nonce)
```

The injected client must implement `verify_id_token(id_token:, client_id:)` by
calling LINE's verification endpoint over authenticated HTTPS with bounded
network timeouts. It must reject unsuccessful responses and return the verified
claims Hash. This gem checks issuer, exact audience, subject, expiry, and an
expected nonce when supplied. A JWT decode-only client is **not** a verifier.
No production network client, OAuth callback, or session creation is bundled.

The host owns nonce generation/one-time consumption, recent-login requirements,
CSRF, session rotation/revocation, and authorization. Never trust `getProfile`,
`getContext`, decoded browser JWTs, group IDs, or display names as identity or
membership evidence. Verified user identity does not establish group membership;
a group warehouse requires a separate server-verified eligibility policy.

## Verification

From sibling `kamigo`, under its Ruby 4 bundle:

```sh
bundle exec ruby -I../kamiliff/lib ../kamiliff/test/v1/security_test.rb
```

Tests use injected claims and local Rack requests, not live LINE authentication.
