# KML-BROWSER-001 — LIFF browser lifecycle (2026-09-16)

Implementation first, then agent CUA manual operation of the loopback page
`python3 script/acceptance/browser_runtime.py`. This page explicitly substitutes
LINE SDK with a synthetic SDK and serves a real HTTP session endpoint. It never
sends a real LINE message or uses production credentials.

Ordered actions and observed results:
1. Click concurrent authenticate: two callers resolve, SDK init1, verified request1.
2. Cancel sharing: cancelled, close0.
3. Unsupported sharing: unsupported, close0.
4. Successful sharing with close: success, close1.
5. Failed sending: delivery_failed, close remains1.
6. Successful sending with close: success, close2.
7. Identity conflict: explicit_link_required, fallback0, close2.
8. Invalid identity: host fallback1, still init1.

Observed through the actual browser controls and visible counters. Afterwards,
`test/browser/runtime.test.cjs` reproduces that sequence at the package's public
JS boundary. Additional package unit cases cover external-browser behavior,
configuration, SDK callback preservation, default login, initialization timeout,
and retry. These unit cases are not claimed as real platform acceptance.

The product's old `/games/work-rank` link was opened in CUA against the real
isolated Rails server. It moved to `/games/puzzle?page=ranking`, real SDK failed
for the synthetic LIFF ID, host OAuth fallback displayed the synthetic LINE
provider. Agent authorized synthetic user, returned to the ranking, and saw the
empty world leaderboard and group selector. Old group link retained group_id=1.
See kamigo_bot docs/acceptance/games/work/line_ranking_liff.md for HTTP coverage.

Real mobile LINE SDK/login and native share UI remain platform verification;
these synthetic checks do not establish that every LINE client behaves alike.
