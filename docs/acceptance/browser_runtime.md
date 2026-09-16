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

## KML-BROWSER-002 — real SDK login return correction
Production v45 CUA reached official LINE Login (not400), but the SDK's default
login return discarded `page=ranking` and returned to the game. This invalidated
the assumption in the original synthetic navigation unit case. Fix: supply
`redirectUri` from the same-origin, endpoint-validated canonical `entryUrl`,
never raw location.href. On the updated loopback UI, click external browser
login: visible redirectUri retains `?page=ranking&group=3`. Updated the matching
public JS contract test after this manual check. Real provider recheck follows
production deployment of1.1.1; no claim that v45 completed ranking login.
