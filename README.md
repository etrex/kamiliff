# Kamiliff 1.1

Rails LIFF view and verified-identity integration. **Breaking rewrite:** old
request forwarding and automatic form-to-chat commands are removed.

## Application navigation

Kamiliff handles LIFF navigation and browser bootstrap. The host owns ordinary
Rails actions, sessions, account linking, authorization and persistence; this
gem creates no database tables and never dispatches a browser-supplied Rails path
or HTTP method. Hotwire forms work normally.

```ruby
# config/initializers/kamiliff.rb
Kamiliff.register_application(:catalog,
  liff_id: ENV.fetch('CATALOG_LIFF_ID'),
  endpoint_path: '/catalog',
  parameters: %w[page group])

# In a view: generated URL opens the registered LIFF application.
kamiliff_url(:catalog, page: 'ranking', group: '123')
# => https://liff.line.me/<ID>?page=ranking&group=123

# In the host controller serving the configured LINE endpoint:
navigation = Kamiliff.application(:catalog).parse(request.query_string)
# Validate business enums and authorize the requested group before use.
```

`Application.new` also works without a global registry. Objects and registries
are frozen; register during boot. `url(**parameters)` generates the LIFF URL;
`entry_path(**parameters)` generates the canonical local endpoint URL.
`parse(raw_query_string)` handles both primary `liff.state=?...` and secondary
redirect parameters, returning a frozen string-key/string-value Hash. It ignores
unrelated direct OAuth/SDK parameters, rejects unknown parameters within
`liff.state`, duplicates, direct/nested overlaps, array/hash navigation syntax,
malformed encoding and oversized input. Values supplied to URL generation may
be strings, integers or booleans (nil omits an allowed optional key), with at most 2048 bytes each; encoded queries
are limited to 8192 bytes (the outer SDK query allows 32768 bytes for percent-encoding expansion). Navigation is public input, never proof of identity,
group membership or permission. The host must configure the actual LINE
endpoint URL consistently with `endpoint_path`.

The JavaScript library is available at `/kamiliff/sdk.js`, including in hosts
without an asset pipeline. It uses a five-minute public cache and conditional
ETag validation. Load the current LINE LIFF SDK before using the library.
Kamiliff does not inject jQuery or Bootstrap, intercept forms, or create an
account session without an explicit host callback.

### Browser lifecycle

Load `/kamiliff/sdk.js` with `defer` before the host bootstrap. The library loads
the official LINE SDK if it is not already present. Configure once per fresh
document; use a full document navigation (`data-turbo="false"` at the LIFF
boundary) when changing applications. It does not intercept Turbo forms.

```javascript
const session = Kamiliff.createSession({
  liffId: serverConfig.liffId,
  endpointPath: serverConfig.endpointPath,
  // Generate on the server with Application#entry_path, preserving allowed args.
  entryUrl: serverConfig.entryUrl,
  sessionUrl: '/sessions/line',
  csrfToken: () => document.querySelector('meta[name="csrf-token"]').content,
  onVerified: data => updateSessionAndCsrf(data),
  fallback: error => startHostLineLogin(error),
  webAuthenticated: false,
  timeout: 10000
});
await session.authenticate();
```

`ready()` initializes the SDK once per document. `authenticate()` shares one
in-flight authentication, obtains an ID token and POSTs JSON `{id_token: ...}`
to the same-origin `sessionUrl` with the host's CSRF token. The endpoint must
verify that token server-side, establish/rotate the host session and return JSON.
`onVerified` lets the host update CSRF/session UI from that response. Set
`webAuthenticated` only from the actual server session; it allows an existing
web session when the SDK is not logged in, without treating browser profile
claims as proof.

When external-browser SDK login is required, `liff.login()` uses the SDK's
current endpoint. The library first directs clean navigation outside that
endpoint to `entryUrl`; it refuses to rewrite an in-progress OAuth/LIFF callback.
The optional host `fallback(error)` handles SDK initialization failures, missing
ID tokens or the explicit JSON error `invalid_line_identity`. A non-2xx
`explicit_link_required` or another verification error fails without fallback;
it must never silently link or switch accounts. Network/invalid-response errors
also fail rather than silently accepting a user. Session and entry URLs must be
same-origin. Navigation pending a redirect intentionally does not resolve.

`sendMessages(messages, {close: true})`, `shareMessages(messages, {close: true})`
and `close()` are exposed on the session. Send/share resolve with a `status`
(`success`, `cancelled` for sharing, or `unsupported`). A cancelled or unavailable
share does not close the window; successful sharing closes only inside LINE.
Global `Kamiliff.sendMessages`, `shareMessages`, `sendText` and `close` delegate
to the most recently configured session for explicit view helpers.

### Existing explicit entries

`register_entry(name) { |controller| ... }` and
`liff_path(entry: 'warehouse', liff_size: :compact)` remain available for existing
1.0 callers. Their `LIFF_COMPACT`, `LIFF_TALL`, and `LIFF_FULL` configuration is
separate from the new application registry. New integrations should use the
application API. Unknown legacy entries return 404; `/liff_route` returns 410.

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
