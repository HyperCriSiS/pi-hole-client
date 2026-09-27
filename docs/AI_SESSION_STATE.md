# AI Session State

Updated: 2026-09-27
Authority: `main`

This is the compact operational handoff for autonomous Pi-hole Client work. `ROADMAP.md` remains the strategic source of truth. Chat/tool history is not project state.

## Baseline
- Repository: `HyperCriSiS/pi-hole-client`
- Default branch: `main`
- Integrated product baseline before this checkpoint-doc commit: `8db7499de712facfae790e2dd9df50b05a69c1fc`
- Open fork pull requests: none.

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
This is the next deterministic code block.

Upstream report:
- server `https://example.com` + subroute `/pihole` should call `https://example.com/pihole/api/...`
- current behavior calls host-root `/api/...`
- v5/v6 are affected; the Android widget depends on the app-created session.
- Web panel uses the stored subroute but a stored `/admin` becomes `/admin/admin/`.

Fork audit already completed:
- `AddServerFullScreen` correctly restores `Uri.path` into the subroute field.
- `buildServerUrl` correctly includes the subroute in the persisted server address.
- therefore persistence/form parsing is not the cause.
- handwritten `PiholeV5ApiClient` builds requests with `Uri.parse(_url).resolve('/admin/api.php')`; the leading slash replaces any configured base path.
- handwritten `PiholeV6ApiClient` similarly resolves leading-slash paths such as `/api/auth`, dropping the configured base path.
- `PiholeV6Service.fromConnection` builds a path-bearing Dio base URL (`<server>/api`) while generated operations use leading-slash paths such as `/auth`; add an explicit transport regression and make this path-safe as part of the same fix.
- the Home server actions menu currently does `openUrl('${server.address}/admin/')`, which explains the `/admin/admin/` case.

## Next autonomous work block
Implement upstream #757 as one bounded short-lived PR.

Target shape:
1. Add/reuse a single path-safe URL helper that joins an endpoint beneath a configured server base path without allowing a leading endpoint slash to reset that path.
2. Apply it to handwritten v5 and handwritten-v6 requests.
3. Make generated-v6 Dio base/path composition explicitly preserve the configured subroute and add a real request-URI regression.
4. Build the web-panel URL without duplicating `/admin` when the configured server path already ends there.
5. Preserve root-path behavior exactly for existing servers without subroutes.
6. Add focused coverage in existing URL, v5 client, v6 client/generated-service and web-panel-adjacent tests.
7. Run normal Dart + unsigned Android gates and merge only after repository-controlled checks pass.

## Existing gates / holds
- #442: Android 16 PopupMenu device confirmation still required.
- #636: Android 17 self-signed HTTPS reproduction/App Log still required before changing TLS behavior.
- #501: widget density/layout device validation still required.
- #293: secure-storage/auth device migration validation still required.
- #134: independent-fork product identity decision still blocks final F-Droid rename/submission.
- #639: handwritten holds remain `/api/info/ftl`, detailed network gateway and gravity streaming for documented schema/behavior reasons.

## Resume protocol
1. Read this file, `ROADMAP.md`, and `UPSTREAM_TRIAGE.md` from `main`.
2. Resolve live `main` and verify it is at or beyond `8db7499d`.
3. Confirm there are no open fork PRs.
4. Start a fresh short-lived branch from `main` for #757.
5. Load only the URL helper, v5/v6 transport, generated-v6 wrapper, web-panel action and matching focused tests.
6. Implement the path-preserving join with root-path backward compatibility and focused regressions.
