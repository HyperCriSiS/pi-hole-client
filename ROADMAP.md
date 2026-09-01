# Pi-hole Client Roadmap

## Project goal

Maintain and improve the unofficial Pi-hole client while upstream activity is limited, preserving stable behavior and importing upstream work selectively rather than blindly.

## Current status

**Status: in progress**

`main` is the canonical integrated baseline. The validated maintenance snapshot was merged through PR #8 on 2026-09-01; the former long-lived `dev` integration PR #2 was closed as superseded after repository-content parity was verified. Future integration work should use short-lived branches/PRs from `main` so validation remains tied to a stable candidate. `UPSTREAM_TRIAGE.md` remains the detailed upstream issue/PR triage reference; this file is the project-level execution roadmap and source of truth for future work.

## Completed foundation

- [x] Add Live Log stalled-request watchdog and regression coverage.
- [x] Import the relevant upstream dependency updates (#659 and #660) into `dev`.
- [x] Implement #432 and #622; verify #592 and #593 are already addressed by current code.
- [x] Implement #632 structured App Log diagnostics with central secret redaction and regression tests for connection/auth/session/secure-storage failures.
- [x] Implement #178 so removing the app-lock passcode immediately clears in-memory lock state, with regression coverage.
- [x] Make the optional SonarQube CI stage skip cleanly when `SONAR_TOKEN` is not configured, avoiding a false-red validation workflow and unnecessary Flutter/analyzer setup.
- [x] Add PR-scoped Actions concurrency to the Dart-test, test-release and docs-deployment workflows so newer commits automatically cancel stale runs without cancelling `main`/release pushes.
- [x] Apply explicit least-privilege `GITHUB_TOKEN` permissions across all current workflows: read-only by default, with narrowly scoped write permissions only for release creation, release preparation, Winget PR creation and version updates; preserve Google Play OIDC requirements.
- [x] Extend Dependabot coverage to the Docusaurus/pnpm website dependency tree so website security and version updates are maintained alongside Dart and GitHub Actions dependencies.
- [x] Repair the September framework-audit CI regressions: analyze `mock_api_server` with its own resolved dependencies, stop coverage/scanner follow-up jobs after a failed test gate, restore generated Git commit metadata before Android builds, and pin pnpm 10 for the docs validation workflow.
- [x] Integrate the validated maintenance snapshot into `main` through PR #8 after green Dart tests, docs validation, unsigned Android source build, CodeQL, Codecov, Sonar and static analysis; close the obsolete long-lived PR #2 after confirming `dev` and `main` resolve to identical repository objects.

## Phase 1 — deterministic UI and diagnostics work

- [x] #604: add Domain Log Details actions for filtering by domain and copying the domain while retaining the browser action.
- [x] #404: complete the deterministic documentation/UI item tracked in `UPSTREAM_TRIAGE.md`.
- [x] #638: introduce/reuse a shared error-state widget and migrate duplicated generic error states incrementally.
  - [x] Twelve migrations to the shared `ErrorMessage` component were verified.
  - [x] Final repository audit completed: remaining direct error icons are shared/specialized components or status indicators, not duplicated generic error layouts.
- [x] #397: reproduce and fix the Windows LocalDNS suggestion focus-dismissal behavior.
  - [x] Root cause isolated to desktop mouse taps on suggestion-list descendants being outside the `TextField` tap region.
  - [x] Keep suggestions and their scrollbar in the `TextField` tap group with `TextFieldTapRegion` while preserving normal outside-click dismissal.
  - [x] Add focused mouse-pointer regression coverage for suggestion selection and outside-click dismissal.
  - [x] Validate the focused autocomplete test and existing Local DNS widget suite in CI; full `Dart Tests` was green for the validated fix.
- [ ] #442: reproduce the PopupMenu/Navigator crash on current `dev` and implement only a verified lifecycle fix.
  - [x] Confirm the upstream report: v1.7.0 on Android 16 crashes in `PopupMenuButtonState._positionBuilder` because `Navigator.of` encounters a detached/null context while laying out the popup route.
  - [x] Confirm there is no upstream closing PR or follow-up stack in the repository triage evidence.
  - [x] Audit relevant current code history: Home server navigation was migrated from direct `Navigator.push` to GoRouter, while `ServerActionsMenu` still uses `PopupMenuButton`; this is a material lifecycle change but not proof that the old crash is fixed.
  - [ ] Reproduce on the current `dev` build on Android 16 while opening/closing the Home server actions popup and navigating/changing server; capture a current stack before changing menu behavior.
  - [ ] If reproduced, add the smallest regression test that exercises the failing popup lifecycle and implement the corresponding mounted/navigation fix.

## Phase 2 — device-dependent regressions

- [ ] #636: reproduce Android 17 connectivity/auth behavior with App Log diagnostics and fix verified network/TLS issues.
- [ ] #598: reproduce Android widget no-data behavior and verify widget update/session restore flow.
- [ ] #501: reproduce the device-dependent issue tracked in `UPSTREAM_TRIAGE.md` before changing behavior.
- [ ] #293: re-test Android auth/secure-storage migration on affected devices after the secure-storage dependency update.

## Phase 3 — larger architecture and distribution work

- [ ] #639 / #352: incrementally improve Pi-hole v6 API support and server-side log filtering with parity tests; keep the proven handwritten/auth path until generated API support is sufficient.
  - [x] Model the FTL-supported server-side query filters (`domain`, `client_ip`, `status`, `type`, `reply`) as `V6QueryFilter`, including normalization and empty-value handling.
  - [x] Wire `V6QueryFilter` into `PiholeV6ApiClient.getQueries` using the existing query-string builder, keeping v5 behavior unchanged.
  - [x] Thread `V6QueryFilter` through `MetricsRepositoryV6` while preserving the shared pagination contract (`start` included); focused v6 model/repository/API regression tests validate the integration.
  - [x] Push semantically safe Logs v6 filters server-side: exact `domain` and exactly one concrete `status`; multi-status/grouped filters remain client-side, v5 remains unchanged, and pagination/filter-capability regression tests cover the transport path.
  - [x] Audit `type` and `reply` mappings: the current Logs UI exposes no independent type/reply filter state, so there is no semantically equivalent UI filter to push server-side yet.
  - [x] Push `client_ip` only for exactly one actively selected client whose value is a valid IPv4/IPv6 literal; hostnames, the all-selected state, and multi-client selections remain client-side; focused regression coverage added.
- [x] Start #639 production migration to the generated OpenAPI client with `/api/info/version`: the generated service now uses the same TLS/pinning policy as the handwritten client, receives the shared SID before each request, and generated HTTP 401 errors participate in the existing SID renewal/retry path. Focused migration tests and the clean full Dart suite are green.
- [x] Migrate `/api/info/sensors` to the same generated service after verifying JSON contract parity; focused FTL/service/SID regression coverage and the full Dart suite are green.
- [x] Migrate `/api/info/metrics` after verifying DNS cache/reply and DHCP payload parity; the repository-wide test job and Codecov upload are green (the historical workflow-level red status came only from the now-optional Sonar stage).
- [x] Migrate `/api/info/system` after verifying generated-schema parity for uptime, memory, process and CPU/load fields; preserve compatibility with pre-FTL-6.1 payloads where `%cpu` is absent, and route SID handling through the generated service.
- [x] Migrate `/api/info/host` after verifying parity for uname, model and DMI payloads; keep the existing domain mapper by round-tripping the generated response into the proven legacy transport model, with focused SID/error regression coverage.
- [x] Migrate `/api/info/messages` read/delete after verifying parity for message IDs, timestamps, types, plain/HTML payloads and delete semantics; preserve existing message-domain filtering while routing SID/error handling through the generated service.
- [ ] Keep `/api/info/ftl` on the handwritten client for now: the generated schema models v6.3 domain/regex counters only as `{total, enabled}` objects, while the existing transport model intentionally accepts the v6.2 integer representation as well.
- [x] Migrate `/api/network/devices/{device_id}` deletion to the generated service with shared SID/retry handling and focused error/ID regression coverage.
- [x] Migrate `/api/network/devices` reads after extending the generated-service wrapper to preserve the existing `max_devices`/`max_addresses` limits; focused repository and wrapper tests verify SID handling, default/custom limit forwarding, response parity and failures.
- [ ] Keep `/api/network/gateway` on the handwritten client for now: the generated response omits `interfaces` and `routes`, which are required to preserve the existing `detailed=true` behavior.
- [x] Migrate `/api/action/flush/logs` and `/api/action/restartdns` to the generated service after verifying action/response parity; preserve handwritten `/api/action/flush/arp`, `/api/action/gravity` and `/api/action/restartdns` streaming/event behavior where generated parity is insufficient.
- [ ] Keep `/api/info/client` on the handwritten client for now: the generated response schema omits metadata required by the current domain model.
- [ ] Keep authentication on the handwritten client for now: the generated POST `/api/auth` model does not expose TOTP, so switching would regress existing authentication behavior.
- [x] #570: implement Local CNAME management for Pi-hole v6 using the generated config API while keeping v5 explicitly unsupported rather than inventing parity.
- [ ] #134: prepare an independently distributable F-Droid-compatible fork.
  - [x] Make release signing conditional so source builds do not require private signing material.
  - [x] Add an unsigned Android source-build CI smoke path.
  - [x] Document the F-Droid boundary and source-build expectations.
  - [x] Replace `mobile_scanner`/Google ML Kit with Flutter `camera` + pure-Dart `zxing2` for the Android QR-token scanner.
  - [x] Keep the source build compatible with compileSdk 36 by constraining secure-storage/permission dependencies instead of silently requiring Android 37 tooling.
  - [x] Isolate the unsigned source build from `sqlite3` precompiled native-binary downloads by using Android system SQLite for that build mode.
  - [x] Validate the unsigned source build in CI and verify with `apksigner` that the release APK is actually unsigned.
  - [ ] Assign a fresh Android Application ID and align name/icon/translations for the independent maintenance fork before creating downstream F-Droid metadata.

## Completion criteria

- [ ] Keep regression tests/builds green for each deterministic change.
- [ ] Validate device-dependent fixes on affected devices before marking them complete.
- [ ] Keep `UPSTREAM_TRIAGE.md` synchronized when an upstream-tracked item changes state.
- [x] Integrate the validated maintenance snapshot into `main` through a stable short-lived PR candidate.
- [ ] Remediate the current Docusaurus/pnpm Dependabot alerts through updates generated from the current `main` dependency graph; validate the docs build before merging dependency changes.

## Blockers / dependencies

- #442 cannot be safely marked fixed from the old v1.7.0 stack alone; a current Android 16 reproduction/log is required because routing and Flutter dependencies have changed substantially since the report.
- Android 17, widget, and secure-storage items require real-device reproduction and logs before they can be considered resolved.
- Larger v6 API work depends on preserving authentication and behavior parity during migration.
- #570 is CI-validated for the v6 repository and Local DNS UI path; v5 CNAME parity must not be assumed because the current v5 Local DNS path is unsupported.
- #134 scanner compliance is resolved: Android no longer uses `mobile_scanner`/Google ML Kit. The source-build path is also isolated from private signing material and from `sqlite3` precompiled-binary downloads and is CI-validated, including an `apksigner` check that the produced release APK is unsigned. A separate F-Droid publication of this maintenance fork still requires a fresh application ID plus corresponding name/icon/string changes before downstream metadata submission.
- GitHub Pages deployment is repository-configuration blocked: the production docs build and Pages artifact upload succeed, but `actions/deploy-pages` receives HTTP 404 until Pages is enabled for this repository with GitHub Actions as the deployment source.
- Website dependency security maintenance is active through Dependabot. Treat regenerated `/website` updates as the remediation path; do not hand-edit `pnpm-lock.yaml`, and do not reuse dependency PRs generated from the pre-integration graph.

## Completion status

**Not fully completed.** #442 remains blocked on a fresh Android 16 reproduction/current stack. #570 is implemented and CI-validated through the v6 repository and Local DNS UI layers. #134 remains the active distribution gate: secret-free unsigned packaging, Android scanner compliance and the download-free native-asset path are implemented and CI-validated; the required independent-fork package identity remains before downstream F-Droid metadata can be submitted. Deterministic #639 generated-client migration can continue in parallel only where schema and behavior parity are proven.
