# Pi-hole Client Roadmap

## Project goal

Maintain and improve the unofficial Pi-hole client while upstream activity is limited, preserving stable behavior and importing upstream work selectively rather than blindly.

## Current status

**Status: in progress**

The active maintenance branch is `dev` and is tracked by PR #2 into `main`. `UPSTREAM_TRIAGE.md` remains the detailed issue/PR triage reference; this file is the project-level execution roadmap and source of truth for future work. The next deterministic item remains #604. Its integration point is confirmed as `lib/ui/logs/widgets/log_details_screen.dart`, with existing Allow/Block behavior and GoRouter detail navigation already in place.

## Completed foundation

- [x] Add Live Log stalled-request watchdog and regression coverage.
- [x] Import the relevant upstream dependency updates (#659 and #660) into `dev`.
- [x] Implement #432 and #622; verify #592 and #593 are already addressed by current code.
- [x] Implement #632 structured App Log diagnostics with central secret redaction and regression tests for connection/auth/session/secure-storage failures.
- [x] Implement #178 so removing the app-lock passcode immediately clears in-memory lock state, with regression coverage.

## Phase 1 — deterministic UI and diagnostics work

- [ ] #604: add Domain Log Details actions for filtering by domain and copying the domain while retaining the browser action.
  - [x] Confirm the current detail route uses `LogDetailsScreen` through GoRouter and preserves the existing Allow/Block action callback.
  - [x] Confirm the existing log-detail tests already cover URL/details and the current allow/block/search behavior, defining the regression surface for the new actions.
  - [ ] Implement copy-domain and filter-by-domain against the current complete screen source, then add focused widget tests.
- [ ] #404: complete the deterministic documentation/UI item tracked in `UPSTREAM_TRIAGE.md`.
- [ ] #638: introduce/reuse a shared error-state widget and migrate screens incrementally.
- [ ] #397: reproduce and fix the Windows LocalDNS suggestion overlay/focus dismissal behavior.
- [ ] #442: investigate the currently triaged deterministic issue and define/implement the smallest verified fix.

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

- The GitHub MCP currently returns `log_details_screen.dart` as blob metadata/SHA rather than the full current file body. Because `create_or_update_file` requires a complete replacement body, #604 must not be implemented by reconstructing and blindly overwriting the screen from historical patches. The route and regression surface are confirmed, but a safe source patch still requires complete current file content.
- Android 17, widget, and secure-storage items require real-device reproduction and logs before they can be considered resolved.
- Larger v6 API work depends on preserving authentication and behavior parity during migration.

## Completion status

**Not fully completed.** #604 is still the next preferred implementation. Its exact integration/test surface is confirmed; the remaining blocker is safe access to the full current `LogDetailsScreen` source through the allowed MCP before applying the UI patch.