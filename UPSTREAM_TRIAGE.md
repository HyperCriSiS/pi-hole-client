# Upstream maintenance triage

Upstream: `tsutsu3/pi-hole-client`

This file tracks the open upstream pull requests and issues reviewed while maintaining this fork.

## Pull requests

| Upstream | Topic | Dev status | Notes |
|---|---|---|---|
| #660 | Dart/Flutter dependency group update | Imported with compatibility adjustment | Upstream test job passes and the dependency group was imported into `dev` through fork PR #1. The later F-Droid Android release-build gate showed that `flutter_secure_storage` 11.x and `permission_handler` 13.x require compileSdk 37, so those two direct dependencies are intentionally constrained to the last Android-36-compatible majors while the rest of the imported update remains. |
| #659 | actions/setup-node v6 -> v7 | Imported | Applied directly to both docs workflows. Upstream test/deploy checks pass; upstream Sonar is unrelated/failing. |
| #646 | TLS certificate inspection/cache refactor | Hold / rework | Upstream PR is still a draft, based on an older `main`, with coverage gates failing. Do not merge wholesale. Rebase/rework before adoption. |
| #484 | ESLint 8 -> 9 | Hold / fix first | Upstream website deployment check fails. Requires ESLint/Docusaurus compatibility work before import. |

## Live Log reliability

### Symptom
Live Log stops receiving new data until the app is restarted.

### Root cause found
`LiveLogsService.tickOnce()` serializes requests with `_liveLoading`, and `LogsViewModel` serializes ticks with `_isLiveTickInProgress`. If a pagination/network future never completes, both guards can remain active indefinitely. Every later timer tick is then skipped. Restarting the app recreates the service/view model and clears the stuck state, matching the reported behavior.

### Fix in `dev`
- Added a per-page timeout watchdog to `LiveLogsService`.
- Timeout/error always releases `_liveLoading` through `finally`.
- The live cursor (`_lastEnd`) advances only after a successful tick, so a timeout does not silently create a data gap.
- Added a regression test with a pagination service that never completes; the test verifies that a timed-out tick unlocks the service and preserves the cursor for retry.

The dependency update from upstream #660 also moves Dio from 5.9.2 to 5.11.0. Dio 5.10/5.11 contains fixes for request/interceptor hangs, which is complementary to the application-level watchdog.

## Open issues

| Issue | Area | Triage / next action |
|---|---|---|
| #639 | Pi-hole v6 API | **In progress in `dev`.** `/api/info/version` is the first full-suite-validated production path on the generated OpenAPI service, preserving TLS/pinning, shared SID injection and generated-401 renewal. `/api/info/sensors` is the next parity-safe read-only migration with focused regression coverage. Keep `/api/info/client` handwritten because its generated schema omits current request metadata, and keep auth handwritten until generated `POST /auth` supports TOTP. |
| #638 | Error UI | **Implemented in `dev`**. Twelve duplicated generic error states were migrated to the shared `ErrorMessage` component; a final repository audit found no further generic duplicates requiring migration. |
| #636 | Android 17 connectivity | Needs device/log reproduction. Dependency refresh in #660 is relevant; collect App Log around connection/auth and verify network/TLS behavior on Android 17. |
| #632 | App Log diagnostics | **Implemented in `dev`**. Added a shared App Log service with central secret redaction, diagnostics for connection/auth/v6 session/secure-storage failures, and persistence-result handling so password/token/SID write errors are no longer silently ignored. Added regression tests for redaction and storage/session failures. |
| #622 | Group/Client sheets | **Implemented in `dev` (`c2765e31`)**. Add sheets are content-sized; edit sheets use centered content with `minHeight: 360` and `maxHeight: 480`, matching Adlist/Domain/Local DNS patterns. |
| #604 | Domain Log Details | **Implemented in `dev`**. Added filter-by-domain and copy-domain actions while retaining the browser action, with focused widget coverage. |
| #598 | Android widgets no data | Needs Android reproduction/logging. Verify widget update channel/session restore on the current pinned secure-storage stack. |
| #593 | v5 navigation | **Already addressed by current code** (`dc683828`, upstream #591): Adlists/Network expose explicit Back buttons with Home fallback and Home tiles push destinations directly. No duplicate production change needed. |
| #592 | Tablet navigation | **Already addressed by current code** (`dc683828`, upstream #591): Settings root uses `PopScope` to route Back to Home; AppShell handles root-tab Back consistently. No duplicate production change needed. |
| #570 | Local CNAME | **Implemented and CI-validated in `dev` for Pi-hole v6.** Added verified CNAME domain/repository CRUD with optional TTL preservation plus a capability-gated Host/CNAME Local DNS UI with add/edit/delete flows and focused regression coverage. The clean `dev` test job is green; Pi-hole v5 remains unchanged because its Local DNS API path does not expose CNAME support. |
| #501 | Android widget layout | Device/density-specific UI work; needs widget size tests across Android display scales. |
| #442 | PopupMenu/Navigator crash | **Current reproduction required.** The only known stack is from v1.7.0 on Android 16. Current `dev` uses GoRouter-based Home navigation but still has `ServerActionsMenu` on `PopupMenuButton`; capture a fresh Android 16 stack before changing popup lifecycle behavior. |
| #438 | disableServer Provider/context crash | Current code already obtains providers before awaiting and checks `context.mounted` before post-request UI work, so the reported v1.7.0 stack appears mitigated in current `main`; retain regression monitoring. |
| #432 | Logs oldest→newest pagination | **Implemented in `dev` (`d4e879da`, tests restored/extended in `6fef1232`)**. Infinite scrolling now follows visual sort direction: newest-first extends older history; oldest-first fetches newer logs from the live baseline, including while automatic Live Log is paused. |
| #404 | Translation docs | **Implemented in `dev`**. Added `docs/translations.md` documenting ARB-based translation contributions and the process for adding new locales. |
| #397 | Windows LocalDNS suggestions | **Implemented and CI-validated in `dev`**. `TextFieldTapRegion` keeps suggestion-list mouse interaction inside the field tap group while outside clicks still dismiss; focused regression tests cover both behaviors. |
| #352 | v6 server-side log filtering | Performance feature. Depends on v6 API capabilities and overlaps #639; keep v5 local filtering. |
| #293 | Android auth/secure-storage crash | Current `dev` deliberately remains on `flutter_secure_storage` 10.x because 11.x requires compileSdk 37 while the project is on 36. Re-test affected Galaxy devices and migration from older app versions before considering resolved; do not conflate that device validation with the F-Droid build-compatibility pin. |
| #178 | App Lock after passcode removal | **Implemented in `dev` (`cc501770`, tests `e6bb9311`)**. Removing the passcode now immediately unlocks the in-memory app state, and loading persisted config synchronizes the lock state with whether a passcode actually exists. |
| #134 | F-Droid | **In progress in `dev`.** Secret-free unsigned Android packaging is isolated from private release signing. `mobile_scanner`/Google ML Kit has been removed and replaced by `camera` + pure-Dart `zxing2`; the F-Droid source-build checkout also switches `sqlite3` to Android system SQLite so it does not fetch a precompiled native library during the build. The download-free unsigned build and `apksigner` unsigned-artifact verification are CI-validated on `3d3e3d74`. F-Droid policy requires this fork to use a fresh Android ID plus corresponding name/icon/string changes for an independent submission, so package identity remains the final product-level gate before downstream `fdroiddata` metadata. |

## Priority order

1. Live Log watchdog + dependency update (implemented in `dev`).
2. #432 and #622 (implemented); #592/#593 verified as already addressed in current code.
3. #632 diagnostics and #178 App Lock (implemented in `dev`).
4. Deterministic UI/docs work (#604, #404, #638, #397) is implemented and validated; #442 is the remaining Phase 1 item and requires a fresh Android 16 reproduction before any lifecycle change.
5. Reproduce/fix device-dependent #636, #598, #501 and #293 on current dependencies.
6. #639/#352: incremental generated-v6 migration is active; `/api/info/version` is full-suite validated and `/api/info/sensors` is the next parity-safe read-only path. #570 is complete. #134 source-build work is CI-validated but downstream submission remains blocked on the required independent-fork package identity.
