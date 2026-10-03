# AI Session State

Updated: 2026-10-03
Authority: `main`

This is the compact operational handoff for autonomous Pi-hole Client work. `ROADMAP.md` remains the strategic source of truth. Chat/tool history is not project state.

## Baseline
- Repository: `HyperCriSiS/pi-hole-client`
- Default branch: `main`
- Current `main`: `4aee4502fbba7137028282d21736f305ca458d9b` (merged PR #130, custom web-interface path support).
- Open fork pull requests: #131 (`feature/query-log-edit-add` -> `main`).
- PR #131 head after updating from `main`: `7c066fc1a444f35b051090fb80189a781c3754c3`.

## 2026-09-27 dependency maintenance block
Four new Dependabot PRs were reviewed against the repository-pinned Flutter 3.44.1 toolchain.

- PR #125 — website dependency group
  - `lucide-react 1.46.0 -> 1.47.0`
  - `@typescript-eslint/parser 8.70.0 -> 8.70.1`
  - `eslint 10.10.0 -> 10.11.0`
  - `prettier 3.9.7 -> 3.9.9`
  - upstream website test deployment was green.
  - squash merged as `628e44e951e5825855d31e241d12f5b6dfe07fae`.

- PR #123 — `sentry_flutter 9.30.0 -> 9.30.1`
  - Dependabot originally introduced unrelated SDK-ahead lockfile churn.
  - `Normalize pub lockfile` regenerated the lock with Flutter 3.44.1; the final delta contains only `sentry_flutter` and `sentry` 9.30.1.
  - Dart tests, lockfile stability, unsigned Android source APK, unsigned-artifact verification, CodeQL, Sonar, Codecov and static analyses passed.
  - the separate GitHub-managed GHAS AI-agent check failed independently as seen on prior PRs.
  - squash merged as `5f1136bb1b84dc69670674cc23bb402379a3cdab`.

- PR #122 — `command_it 9.5.1 -> 9.5.2`
  - Dependabot's initial lockfile likewise contained unrelated SDK-ahead packages.
  - pinned normalization reduced the final delta to `command_it 9.5.2` plus required `listen_it 6.0.0`.
  - Dart tests, lockfile stability, unsigned Android source APK, unsigned-artifact verification, CodeQL, Sonar, Codecov and static analyses passed.
  - the separate GitHub-managed GHAS AI-agent check again failed independently.
  - squash merged as `1a870bedd96809b270ca9eac8501624483e0a144`.

- PR #124 — `freezed 3.2.5 -> 4.0.2`
  - closed without merge.
  - Flutter 3.44.1 provides Dart 3.12.1; Freezed 4.0.2 requires Dart >=3.13.
  - the failure occurs at `flutter pub get`, before tests/builds; do not force SDK/analyzer overrides.

- PR #126 — Dependabot exact-version holds
  - added exact ignores for `freezed 4.0.2`, `mockito 5.8.1`, and `sqlite3 3.6.0`.
  - all three were independently reproduced as unresolvable on the pinned toolchain.
  - later versions remain visible to Dependabot; no broad package freeze was introduced.
  - GitHub's native `.github/dependabot.yml` validation, Dart tests, unsigned Android source build, CodeQL, Sonar, Codecov and static analyses passed.
  - squash merged as `8db7499de712facfae790e2dd9df50b05a69c1fc`.

## 2026-10-02 #666 explicit-refresh TOTP recovery
- Upstream issue #666 remains applicable; upstream PR #762 only wired Sessions and its review noted broader screen-level refresh coverage.
- Fork PR #129 completed the mechanism across all identified explicit user refresh paths: Sessions, DHCP, Interfaces, Local DNS, Network, Server Info, Clients, Groups, Domains, Adlists and Logs.
- Added `refreshWithTotpRecovery`: explicit refresh clears a previously declined marker, runs the requested load, invokes the existing TOTP reconnect flow on `TotpRequiredException`, then retries that exact load once after successful recovery.
- Initial/automatic/background loads deliberately do not use this helper, preventing repeated interactive prompts.
- Focused tests cover normal refresh, declined-state reset, successful recovery/retry, failed recovery and non-TOTP passthrough.
- All repository-controlled gates passed, including full Dart tests, unsigned Android source build + artifact verification, CodeQL, Sonar, Codecov, GHAS and static analyses.
- Squash merge: `cedf40c26a194224f0f17ed3a7a9c744affd61a2`.

## Upstream refresh
Open upstream PRs remain unchanged:
- #737 dependency group: already triaged; remaining incompatible parts are now protected by exact fork Dependabot ignores where applicable.
- #646 TLS certificate/cache refactor: still a large draft/rework hold.
- #484 ESLint 8->9: superseded by the fork's validated ESLint 10 path.

Two upstream issues changed since the previous checkpoint:

### #754 — Gravity update behind nginx
- Upstream reproduced the report.
- nginx defaults to `proxy_buffering on`; through the app's HTTP/1.1 streaming request, nginx can withhold response data until the gravity operation finishes.
- the app then hits its existing 10-second wait for the streaming response.
- `proxy_buffering off` restored line-by-line gravity output; the reporter confirmed the workaround works.
- This is additional evidence for the existing handwritten gravity-streaming compatibility hold. Do not replace the stream path or attempt an HTTP/2 migration as a quick fix.

### #757 — configured subroute ignored
Implemented in fork PR #128 and squash-merged as `39a94cfd9833c1a1ee8afca8a13a2026e5a6d898`.

Root cause:
- server form/persistence already kept the configured URI path correctly
- handwritten v5/v6 used leading-slash `Uri.resolve`, which reset that path
- generated-v6 operations also emitted leading-slash paths against a path-bearing Dio base
- the web-panel action appended `/admin/` blindly

Fix:
- added shared `resolveServerUri` path joining with suffix/prefix overlap de-duplication
- preserved existing root-server behavior
- applied the helper to v5 and handwritten-v6 requests
- generated-v6 now uses a subroute-preserving `/api/` base and a small interceptor that makes generated non-absolute operation paths relative
- web-panel URL uses the same path-safe join, so an existing `/admin` path is not duplicated
- helper tests cover root paths, custom subroutes, overlapping API/admin segments and query preservation
- v5 and handwritten-v6 regressions assert exact request URIs
- a loopback `HttpServer` regression verifies the real generated-v6 request path is `/pihole/api/auth`

Validation:
- full Dart test suite passed
- unsigned Android source APK passed
- unsigned-artifact verification passed
- CodeQL, Sonar, Codecov, audit and static analyses passed
- only the known separate GitHub-managed GHAS AI-agent job failed independently of repository-controlled gates

## 2026-10-03 #759 custom web-interface path
- Fork PR #130 merged into `main` as `4aee4502fbba7137028282d21736f305ca458d9b`.
- The implementation separates Pi-hole's web-home capability from the API/reverse-proxy subroute, reads v6 `webserver.paths.webhome`/prefix when available, and preserves the legacy `/admin/` fallback for v5/older servers.
- Focused config/helper/action tests and repository-controlled CI gates passed before merge.

## 2026-10-03 #689 Query Log edit-and-add
- Fork PR #131 is open from `feature/query-log-edit-add` and has been updated onto current `main`.
- `AddDomainModal` accepts an optional initial domain, initializes validation state from it, and disposes its controller.
- Log Details exposes an Edit & Add action that opens the existing Add Domain flow prefilled with the queried domain; the default allow/deny direction mirrors the existing direct action and exact/regex remains editable in the modal.
- Focused widget coverage asserts that the modal opens with the selected domain and that Add is immediately enabled for a valid prefilled domain.
- Dart tests, Sonar, Codecov, CodeQL, GHAS and static analyses are green on PR #131; the unsigned Android source APK is the remaining running gate.
- Final manual diff review found no code blocker, but did catch stale checkpoint documentation from before PR #130. This branch cleanup removes that stale state before merge.

## Next autonomous work block
1. Wait for the final unsigned Android source APK gate on PR #131.
2. If all repository-controlled gates remain green, squash-merge PR #131.
3. Update `ROADMAP.md`, `UPSTREAM_TRIAGE.md`, and this checkpoint to mark #689 integrated.
4. Start #748 connection/session architecture work as the next larger incremental block.

## Existing gates / holds
- #442: Android 16 PopupMenu device confirmation still required.
- #636: Android 17 self-signed HTTPS reproduction/App Log still required before changing TLS behavior.
- #501: widget density/layout device validation still required.
- #293: secure-storage/auth device migration validation still required.
- #134: independent-fork product identity decision still blocks final F-Droid rename/submission.
- #639: handwritten holds remain `/api/info/ftl`, detailed network gateway and gravity streaming for documented schema/behavior reasons.

## Resume protocol
1. Read this file, `ROADMAP.md`, and `UPSTREAM_TRIAGE.md` from `main`.
2. Resolve live `main` and confirm PR #131 status if it is still open.
3. If PR #131 is merged, begin #748 as a fresh bounded architecture slice.
4. Keep device-gated #442/#636/#501/#293 validation-only until affected-device evidence exists.
5. Validate repository-controlled gates before every merge.
