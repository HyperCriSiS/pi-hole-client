# Pi-hole Client Roadmap

## Project goal

Maintain and improve the unofficial Pi-hole client while upstream activity is limited, preserving stable behavior and importing upstream work selectively rather than blindly.

## Current status

**Status: in progress**

The active maintenance branch is `dev` and is tracked by PR #2 into `main`. `UPSTREAM_TRIAGE.md` remains the detailed issue/PR triage reference; this file is the project-level execution roadmap and source of truth for future work. Work on #638 is underway: duplicated error states in Find Domains in Lists, ClientsList, GroupsList and StatisticsList have been migrated to the shared `ErrorMessage` component, while the broader incremental screen migration remains open.

## Completed foundation

- [x] Add Live Log stalled-request watchdog and regression coverage.
- [x] Import the relevant upstream dependency updates (#659 and #660) into `dev`.
- [x] Implement #432 and #622; verify #592 and #593 are already addressed by current code.
- [x] Implement #632 structured App Log diagnostics with central secret redaction and regression tests for connection/auth/session/secure-storage failures.
- [x] Implement #178 so removing the app-lock passcode immediately clears in-memory lock state, with regression coverage.

## Phase 1 — deterministic UI and diagnostics work

- [x] #604: add Domain Log Details actions for filtering by domain and copying the domain while retaining the browser action.
  - [x] Confirm the current detail route uses `LogDetailsScreen` through GoRouter and preserves the existing Allow/Block action callback.
  - [x] Confirm the existing log-detail tests already cover URL/details and the current allow/block/search behavior, defining the regression surface for the new actions.
  - [x] Implement copy-domain and filter-by-domain against the current complete screen source, then add focused widget tests (14/14 `LogDetailsScreen` widget tests green).
- [x] #404: document the current translation contribution workflow (`docs/translations.md`): existing languages are edited in `lib/ui/core/l10n/*.arb` and submitted by PR; new languages start with an issue; no Weblate/Crowdin project is currently in use.
- [ ] #638: introduce/reuse a shared error-state widget and migrate screens incrementally.
- [x] Migrate the Find Domains in Lists error result to the shared `ErrorMessage` component and keep the focused screen test green (`809ba6cc`).
- [x] Migrate `ClientsList` to the shared `ErrorMessage` component and keep the focused group/client test green (`280cf3d2`).
- [x] Migrate `GroupsList` to the shared `ErrorMessage` component and keep the focused group/client test green (`bf67381`).
- [x] Migrate `StatisticsList` to the shared `ErrorMessage` component and keep `statistics_test.dart` green (9/9, `03864ddb`).
- [ ] Migrate the next verified duplicated statistics error state (`DnsTab`) to `ErrorMessage` and keep the statistics regression suite green.
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

- Android 17, widget, and secure-storage items require real-device reproduction and logs before they can be considered resolved.
- Larger v6 API work depends on preserving authentication and behavior parity during migration.

## Completion status

**Not fully completed.** #604 and #404 are implemented and validated. #638 is in progress; four duplicated error states are already standardized, and `DnsTab` is the next verified migration candidate.
