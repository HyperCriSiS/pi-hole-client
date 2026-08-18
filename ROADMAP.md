# Pi-hole Client Roadmap

## Project goal

Maintain and improve the unofficial Pi-hole client while upstream activity is limited, preserving stable behavior and importing upstream work selectively rather than blindly.

## Current status

**Status: in progress**

The active maintenance branch is `dev` and is tracked by PR #2 into `main`. `UPSTREAM_TRIAGE.md` remains the detailed upstream issue/PR triage reference; this file is the project-level execution roadmap and source of truth for future work. #604, #404, #638 and #397 are complete. #442 is now the active Phase 1 item; the original report is from v1.7.0 on Android 16 and must be reproduced against current `dev` before a lifecycle fix can be justified.

## Completed foundation

- [x] Add Live Log stalled-request watchdog and regression coverage.
- [x] Import the relevant upstream dependency updates (#659 and #660) into `dev`.
- [x] Implement #432 and #622; verify #592 and #593 are already addressed by current code.
- [x] Implement #632 structured App Log diagnostics with central secret redaction and regression tests for connection/auth/session/secure-storage failures.
- [x] Implement #178 so removing the app-lock passcode immediately clears in-memory lock state, with regression coverage.

## Phase 1 — deterministic UI and diagnostics work

- [x] #604: add Domain Log Details actions for filtering by domain and copying the domain while retaining the browser action; focused widget coverage is green.
- [x] #404: document the translation contribution workflow in `docs/translations.md`; existing languages use `lib/ui/core/l10n/*.arb`, new languages start with an issue, and no hosted translation platform is currently used.
- [x] #638: introduce/reuse a shared error-state widget and migrate duplicated generic error states incrementally.
  - [x] Twelve migrations to the shared `ErrorMessage` component were verified.
  - [x] Final repository audit completed: remaining direct error icons are shared/specialized components or status indicators, not duplicated generic error layouts.
- [x] #397: reproduce and fix the Windows LocalDNS suggestion focus-dismissal behavior.
  - [x] Root cause isolated to desktop mouse taps on suggestion-list descendants being outside the `TextField` tap region.
  - [x] Keep suggestions and their scrollbar in the `TextField` tap group with `TextFieldTapRegion` while preserving normal outside-click dismissal.
  - [x] Add focused mouse-pointer regression coverage for suggestion selection and outside-click dismissal.
  - [x] Validate the focused autocomplete test and existing Local DNS widget suite in CI; full `Dart Tests` is green on commit `2444b03c`.
- [ ] #442: reproduce the PopupMenu/Navigator crash on current `dev` and implement only a verified lifecycle fix.
  - [x] Confirm the upstream report: v1.7.0 on Android 16 crashes in `PopupMenuButtonState._positionBuilder` because `Navigator.of` encounters a detached/null context while laying out the popup route.
  - [x] Confirm there is no upstream closing PR or follow-up stack, and the issue remains open.
  - [x] Audit relevant current code history: Home server navigation was migrated from direct `Navigator.push` to GoRouter in upstream #548, but `ServerActionsMenu` still uses `PopupMenuButton`; this is a material lifecycle change but not proof that the old crash is fixed.
  - [ ] Reproduce on the current `dev` build on Android 16 while opening/closing the Home server actions popup and navigating/changing server; capture a current stack before changing menu behavior.
  - [ ] If reproduced, add the smallest regression test that exercises the failing popup lifecycle and implement the corresponding mounted/navigation fix.

## Phase 2 — device-dependent regressions

- [ ] #636: reproduce Android 17 connectivity/auth behavior with App Log diagnostics and fix verified network/TLS issues.
- [ ] #598: reproduce Android widget no-data behavior and verify widget update/session restore flow.
- [ ] #501: reproduce the device-dependent issue tracked in `UPSTREAM_TRIAGE.md` before changing behavior.
- [ ] #293: re-test Android auth/secure-storage migration on affected devices after the secure-storage dependency update.

## Phase 3 — larger architecture and distribution work

- [ ] #639 / #352: incrementally improve Pi-hole v6 API support and server-side log filtering with parity tests; keep the proven handwritten/auth path until generated API support is sufficient.
- [ ] #570: implement the larger feature only after the preceding compatibility work is stable.
- [ ] #134: establish reproducible F-Droid-compatible build metadata and release packaging.

## Validation and completion criteria

- [ ] Keep regression tests/builds green for each deterministic change.
- [ ] Validate device-dependent fixes on affected devices before marking them complete.
- [ ] Keep `UPSTREAM_TRIAGE.md` synchronized when an upstream-tracked item changes state.
- [ ] Merge the validated maintenance work from `dev` according to the repository's existing PR workflow.

## Blockers / dependencies

- #442 cannot be safely marked fixed from the 2025 v1.7.0 stack alone; a current Android 16 reproduction/log is required because routing and Flutter dependencies have changed substantially since the report.
- Android 17, widget, and secure-storage items require real-device reproduction and logs before they can be considered resolved.
- Larger v6 API work depends on preserving authentication and behavior parity during migration.

## Completion status

**Not fully completed.** #397 is implemented and fully CI-validated. #442 is the active item and currently requires a fresh Android 16 reproduction/current stack before a code change is justified.
