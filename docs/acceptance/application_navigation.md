# Application navigation and SDK delivery, 2026-09-16

Agent exercised executable public Ruby interfaces before adding regression tests.
This is local framework acceptance, not a live LINE authentication result.

## KAMILIFF-NAV-001

Create/register `manual_catalog`, LIFF ID `123-abc`, endpoint `/catalog`, allowed
parameters `page` and `group`. Generate URL with `page=ranking,group=123`:
`https://liff.line.me/123-abc?page=ranking&group=123`. Generate local entry:
`/catalog?page=ranking`. Parse
`liff.state=%3Fpage%3Dranking%26group%3D123&code=oauth`: returns exactly
`{"page"=>"ranking", "group"=>"123"}`. Parse secondary query
`page=ranking&code=oauth&state=nonce`: returns only `page=ranking`.
Registry returns the configured frozen application and its allowlist is frozen.
All observed as expected. A later public API check passed `group: nil`:
URL omits group; an unknown key with nil still rejects. A 2048-byte `%` value
round-trips through the primary redirect's double escaping (10261-byte outer
query), proving the larger wire limit accommodates generated navigation.

## KAMILIFF-NAV-002

Using the same configuration, individually call `parse` with duplicate `page`,
unknown nested `path=/admin`, direct/nested conflicting `page`, `group[]=1`,
invalid UTF-8 `%FF`, incomplete escape `%`, path-shaped `liff.state=/admin`, and
2049-byte page value. Each raises ArgumentError. Array value for URL generation
and endpoint `//evil.test` also reject. These were executed before tests.

## KAMILIFF-SDK-001

Run `bundle exec ruby -Ilib script/acceptance/sdk_delivery.rb`. This boots a real
Rails host without asset pipeline and performs public Rack requests to
`GET /kamiliff/sdk.js` without an XHR header. Initially this exposed Rails'
cross-origin JavaScript protection returning 422. After exempting only this
public, non-personalized static action, the same request returns 200 with the
exact packaged JS, JavaScript content type, and `max-age=300, public`.
Repeat with its ETag in If-None-Match: 304, empty body. Automated integration
runs this exact executable. No browser execution or live LINE is claimed here;
browser lifecycle acceptance is recorded separately.
