# Upstream maintenance triage

Upstream: `tsutsu3/pi-hole-client`

This file tracks the open upstream pull requests and issues reviewed while maintaining this fork.

## Pull requests

| Upstream | Topic | Dev status | Notes |
|---|---|---|---|
| #660 | Dart/Flutter dependency group update | Imported | Upstream test job passes. Imported into `dev` through fork PR #1. Includes Dio 5.11.0 and flutter_secure_storage 11.0.0 among other updates. |
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
| #639 | Pi-hole v6 API | Large refactor. Keep handwritten auth path until generated OpenAPI schema supports `totp`; migrate repository calls incrementally and add parity tests. |
| #638 | Error UI | Design cleanup. Introduce/reuse one shared error-state widget and migrate screens incrementally. |
| #636 | Android 17 connectivity | Needs device/log reproduction. Dependency refresh in #660 is relevant; collect App Log around connection/auth and verify network/TLS behavior on Android 17. |
| #632 | App Log diagnostics | **Implemented in `dev`**. Added a shared App Log service with central secret redaction, diagnostics for connection/auth/v6 session/secure-storage failures, and persistence-result handling so password/token/SID write errors are no longer silently ignored. Added regression tests for redaction and storage/session failures. |
| #622 | Group/Client sheets | **Implemented in `dev` (`c2765e31`)**. Add sheets are content-sized; edit sheets use centered content with `minHeight: 360` and `maxHeight: 480`, matching Adlist/Domain/Local DNS patterns. |
| #604 | Domain Log Details | Feature work: add filter-by-domain and copy-domain quick actions; keep browser action. |
| #598 | Android widgets no data | Needs Android reproduction/logging. Verify widget update channel/session restore after #660 secure-storage update. |
| #593 | v5 navigation | **Already addressed by current code** (`dc683828`, upstream #591): Adlists/Network expose explicit Back buttons with Home fallback and Home tiles push destinations directly. No duplicate production change needed. |
| #592 | Tablet navigation | **Already addressed by current code** (`dc683828`, upstream #591): Settings root uses `PopScope` to route Back to Home; AppShell handles root-tab Back consistently. No duplicate production change needed. |
| #570 | Local CNAME | Feature/API work. Add CNAME domain model/repository operations and UI tab after confirming v5/v6 API support. |
| #501 | Android widget layout | Device/density-specific UI work; needs widget size tests across Android display scales. |
| #442 | PopupMenu/Navigator crash | Needs reproduction/current stack. Old report is from v1.7.0 and points to a popup route losing its Navigator/context. Audit async popup/menu lifecycle and mounted checks. |
| #438 | disableServer Provider/context crash | Current code already obtains providers before awaiting and checks `context.mounted` before post-request UI work, so the reported v1.7.0 stack appears mitigated in current `main`; retain regression monitoring. |
| #432 | Logs oldest→newest pagination | **Implemented in `dev` (`d4e879da`, tests restored/extended in `6fef1232`)**. Infinite scrolling now follows visual sort direction: newest-first extends older history; oldest-first fetches newer logs from the live baseline, including while automatic Live Log is paused. |
| #404 | Translation docs | Documentation task: add clear translation contribution instructions/link to README/website/About contribution docs. |
| #397 | Windows LocalDNS suggestions | Desktop focus/overlay bug; reproduce with mouse scrollbar and suggestion taps, then prevent outside-tap dismissal for interactions inside the suggestion overlay. |
| #352 | v6 server-side log filtering | Performance feature. Depends on v6 API capabilities and overlaps #639; keep v5 local filtering. |
| #293 | Android auth/secure-storage crash | Current code already moved to flutter_secure_storage 10.x; #660 moves to 11.0.0. Re-test affected Galaxy devices and migration from older app versions before considering resolved. |
| #178 | App Lock after passcode removal | **Implemented in `dev` (`cc501770`, tests `e6bb9311`)**. Removing the passcode now immediately unlocks the in-memory app state, and loading persisted config synchronizes the lock state with whether a passcode actually exists. |
| #134 | F-Droid | Packaging/release work rather than app code. Requires reproducible F-Droid-compatible build metadata and release process. |

## Priority order

1. Live Log watchdog + dependency update (implemented in `dev`).
2. #432 and #622 (implemented); #592/#593 verified as already addressed in current code.
3. #632 diagnostics and #178 App Lock (implemented in `dev`).
4. Implement deterministic UI/docs items (#604, #404, #638) and investigate #397/#442.
5. Reproduce/fix device-dependent #636, #598, #501 and #293 on current dependencies.
6. #639/#352 and #570: larger API architecture/features; #134 release packaging.
