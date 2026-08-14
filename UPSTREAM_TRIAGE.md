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
| #632 | App Log diagnostics | Implement structured redacted logs around connection, auth/session restore and secure-storage failures. High value because it also helps #636/#293. |
| #622 | Group/Client sheets | Straightforward UI consistency task: align edit sheets to centered 360–480 layout and add sheets to content-sized layout. |
| #604 | Domain Log Details | Feature work: add filter-by-domain and copy-domain quick actions; keep browser action. |
| #598 | Android widgets no data | Needs Android reproduction/logging. Verify widget update channel/session restore after #660 secure-storage update. |
| #593 | v5 navigation | Reproduce on v5 and ensure Adlists/Network destinations expose a back affordance when launched from Home tiles. |
| #592 | Tablet navigation | Reproduce tablet nested navigation and route back from Settings root to Home instead of terminating the app. |
| #570 | Local CNAME | Feature/API work. Add CNAME domain model/repository operations and UI tab after confirming v5/v6 API support. |
| #501 | Android widget layout | Device/density-specific UI work; needs widget size tests across Android display scales. |
| #442 | PopupMenu/Navigator crash | Needs reproduction/current stack. Old report is from v1.7.0 and points to a popup route losing its Navigator/context. Audit async popup/menu lifecycle and mounted checks. |
| #438 | disableServer Provider/context crash | Current code already obtains providers before awaiting and checks `context.mounted` before post-request UI work, so the reported v1.7.0 stack appears mitigated in current `main`; retain regression monitoring. |
| #432 | Logs oldest→newest pagination | Logic bug. Pagination direction must follow sort order; reaching the bottom in ascending order should extend toward newer timestamps while keeping scroll position stable. |
| #404 | Translation docs | Documentation task: add clear translation contribution instructions/link to README/website/About contribution docs. |
| #397 | Windows LocalDNS suggestions | Desktop focus/overlay bug; reproduce with mouse scrollbar and suggestion taps, then prevent outside-tap dismissal for interactions inside the suggestion overlay. |
| #352 | v6 server-side log filtering | Performance feature. Depends on v6 API capabilities and overlaps #639; keep v5 local filtering. |
| #293 | Android auth/secure-storage crash | Current code already moved to flutter_secure_storage 10.x; #660 moves to 11.0.0. Re-test affected Galaxy devices and migration from older app versions before considering resolved. |
| #178 | App Lock after passcode removal | Old state-lifecycle bug; reproduce current build and ensure in-memory lock state is cleared immediately when passcode is removed, not only after process restart. |
| #134 | F-Droid | Packaging/release work rather than app code. Requires reproducible F-Droid-compatible build metadata and release process. |

## Priority order

1. Live Log watchdog + dependency update (implemented in `dev`).
2. #632 diagnostics, because it makes Android/network/auth failures diagnosable.
3. Reproduce/fix #636, #598, #293 and #178 on current dependencies.
4. #432, #593, #592 and #622: bounded application/UI bugs.
5. #639/#352 and #570: larger API architecture/features.
6. Design/docs/release work (#638, #604, #501, #404, #397, #134).
