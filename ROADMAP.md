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
- [ ] #442: reproduce the PopupMenu/Navigator crash on current `main` and implement only a verified lifecycle fix.
  - [x] Confirm the upstream report: v1.7.0 on Android 16 crashes in `PopupMenuButtonState._positionBuilder` because `Navigator.of` encounters a detached/null context while laying out the popup route.
  - [x] Confirm there is no upstream closing PR or follow-up stack in the repository triage evidence.
  - [x] Audit relevant current code history: Home server navigation was migrated from direct `Navigator.push` to GoRouter, while `ServerActionsMenu` still uses `PopupMenuButton`; this is a material lifecycle change but not proof that the old crash is fixed.
  - [ ] Reproduce on the current `main` baseline (or a short-lived branch created from it) on Android 16 while opening/closing the Home server actions popup and navigating/changing server; capture a current stack before changing menu behavior.
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
- [x] Migrate `/api/history` activity metrics to the generated service after verifying parity for timestamps and total/cached/blocked/forwarded counters; preserve the proven domain mapper by round-tripping the generated response through the legacy transport model, and keep shared SID renewal/retry behavior under focused regression coverage.
- [x] Migrate `/api/history/clients` to the generated service after adding explicit `N`/count forwarding; preserve default/custom/null count semantics, the proven legacy domain mapper via generated-JSON roundtrip, and shared SID renewal/retry behavior. The full Dart suite, unsigned Android source APK, CodeQL/static analysis and zero open code-scanning alerts are green on the final PR #34 candidate.
- [x] Migrate `/api/stats/summary` to the generated service after verifying summary-field parity; preserve the proven legacy domain mapper through generated-JSON roundtrip and shared SID renewal/retry behavior with focused repository regression coverage.
- [ ] Keep `/api/info/ftl` on the handwritten client for now: the generated schema models v6.3 domain/regex counters only as `{total, enabled}` objects, while the existing transport model intentionally accepts the v6.2 integer representation as well.
- [x] Migrate `/api/network/devices/{device_id}` deletion to the generated service with shared SID/retry handling and focused error/ID regression coverage.
- [x] Migrate `/api/network/devices` reads after extending the generated-service wrapper to preserve the existing `max_devices`/`max_addresses` limits; focused repository and wrapper tests verify SID handling, default/custom limit forwarding, response parity and failures.
- [ ] Keep `/api/network/gateway` on the handwritten client for now: the generated response omits `interfaces` and `routes`, which are required to preserve the existing `detailed=true` behavior.
- [x] Migrate `/api/action/flush/logs` and `/api/action/restartdns` to the generated service; both keep the shared SID renewal/retry path and map their generated responses back to the repository's `Unit` contract.
- [x] Migrate `/api/dhcp` lease reads and `/api/dhcp/{ip}` deletion after verifying generated-schema parity for expiry, host/client identifiers, addresses and timing; preserve the existing domain mapping while moving SID/retry handling to the generated service.
- [x] Migrate `/api/dns/blocking` reads and updates to the generated service; preserve `skipRenewal` behavior, enable/disable semantics and the disable timer while keeping the existing domain mapping.
- [ ] Keep ARP/network flushing on the handwritten path for now because the repository intentionally falls back from the v6.3+ `/api/action/flush/network` endpoint to deprecated `/api/action/flush/arp` on HTTP 404; keep gravity update handwritten because the current client exposes the streaming progress contract while the generated endpoint does not.
- [ ] Continue #639 only endpoint-by-endpoint where the generated schema preserves behavior. Keep `/api/info/client` on the handwritten client because the generated schema omits request metadata used by the current model, and keep authentication on the handwritten path while generated `POST /auth` lacks TOTP support.
- [x] #570: add Local CNAME management only on API paths whose behavior is verified.
  - [x] Verify the current API/repository support boundary: Pi-hole v6 already models `dns.cnameRecords` in `Dns`, while the v5 Local DNS repository/gateway path remains explicitly unsupported.
  - [x] Add v6 CNAME repository/domain operations over `dns/cnameRecords`; implementation committed (`d7c6b6e3`) with optional TTL preservation and shared v6 session/retry behavior. Repository-wide Flutter tests and Codecov completed successfully on the implementation; v5 remains explicitly unsupported.
  - [x] Add focused v6 API/repository regression tests for reading, adding, updating and deleting CNAME records, including restart/error handling. Fetch/add/delete success and CRUD error paths are covered by `3b9d9ac`; successful update, TTL parsing/preservation and explicit DNS-restart assertions were added in `6f224932`. The recording fake signature was corrected in `1ae8e1a5`; the subsequent Dart Tests job and Codecov upload completed successfully. The workflow-level failure came from the separate SonarQube scan, not the CNAME regression suite.
  - [x] Integrate tested v6 CNAME management into the Local DNS UI: capability-gated Host/CNAME switcher, CNAME list, add/edit/delete dialog, optional TTL handling, local state updates, and focused ViewModel regression coverage. Pi-hole v5 remains unchanged because it does not expose the CNAME repository capability.
- [ ] #134: establish reproducible F-Droid-compatible build metadata and release packaging.
  - [x] Make Android release signing conditional: normal signed GitHub releases still use `android/key.properties`, while clean source builds can produce an unsigned release APK without private signing material.
  - [x] Add a secret-free unsigned Android source-build smoke job to the existing release-test workflow using Java 17, Flutter 3.44.1, `.env.sample`, and the generated Git commit hash.
  - [x] Document the F-Droid source-build boundary and keep downstream `fdroiddata` metadata separate from this application repository.
  - [x] Replace `mobile_scanner`/Google ML Kit on Android with a FLOSS scanner backend while preserving the QR token-import flow and focused regression coverage. The Android path now uses Flutter `camera` plus the pure-Dart `zxing2` decoder; the existing `ScanTokenModal`/navigation contract remains intact.
  - [x] Keep the F-Droid/source-build dependency path compatible with Android compileSdk 36: constrain `flutter_secure_storage` and `permission_handler` to the last compatible majors instead of forcing an unrelated SDK/AGP migration.
  - [x] Remove the `sqlite3` native-asset binary download from the F-Droid/unsigned Android build path by switching that isolated build checkout to Android system SQLite; regular signed/desktop builds keep their existing bundled SQLite behavior.
  - [x] Confirm the final unsigned source-build CI gate on the download-free path; CI on `3d3e3d74` completed successfully and `apksigner` verified that the produced release APK is unsigned.
  - [ ] Resolve package identity before an independent fork submission: this maintenance fork currently retains `io.github.tsutsu3.pi_hole_client`; F-Droid policy requires a fork to use a fresh Android Application ID plus corresponding name, icon and translated string changes. The rename affects Gradle namespace/applicationId, the Kotlin package tree (main/debug/release/tests/widgets) and release metadata, so it must be handled as a dedicated migration.
  - [ ] Draft and validate the downstream F-Droid build metadata after the package-identity gate is resolved.

## Validation and completion criteria

- [ ] Keep regression tests/builds green for each deterministic change.
- [ ] Validate device-dependent fixes on affected devices before marking them complete.
- [ ] Keep `UPSTREAM_TRIAGE.md` synchronized when an upstream-tracked item changes state.
- [x] Integrate the validated maintenance snapshot into `main` through a stable short-lived PR candidate.
- [x] Remediate all currently patchable Docusaurus/pnpm high-severity Dependabot alerts through updates generated from the current `main` dependency graph; the remaining two `image-size` high-severity advisories have no patched release and are bounded by the existing 15-minute docs-build timeout.

## Blockers / dependencies

- #442 cannot be safely marked fixed from the old v1.7.0 stack alone; a current Android 16 reproduction/log is required because routing and Flutter dependencies have changed substantially since the report.
- Android 17, widget, and secure-storage items require real-device reproduction and logs before they can be considered resolved.
- Larger v6 API work depends on preserving authentication and behavior parity during migration.
- #570 is CI-validated for the v6 repository and Local DNS UI path; v5 CNAME parity must not be assumed because the current v5 Local DNS path is unsupported.
- #134 scanner compliance is resolved: Android no longer uses `mobile_scanner`/Google ML Kit. The source-build path is also isolated from private signing material and from `sqlite3` precompiled-binary downloads and is CI-validated, including an `apksigner` check that the produced release APK is unsigned. A separate F-Droid publication of this maintenance fork still requires a fresh application ID plus corresponding name/icon/string changes before downstream metadata submission.
- GitHub Pages is enabled with GitHub Actions as the deployment source; the two latest production docs deployments from `main` completed successfully after the repository setting was corrected.
- Website dependency security maintenance remains active through Dependabot. The only currently open high-severity alerts are the two unpatched `image-size <=2.0.2` parser DoS advisories; retain the 15-minute build timeout as a compensating control and continue to resolve future lockfile changes reproducibly rather than hand-editing `pnpm-lock.yaml`.

## Completion status

**Not fully completed.** #442 remains blocked on a fresh Android 16 reproduction/current stack. #570 is implemented and CI-validated through the v6 repository and Local DNS UI layers. #134 remains the active distribution gate: secret-free unsigned packaging, Android scanner compliance and the download-free native-asset path are implemented and CI-validated; the required independent-fork package identity remains before downstream F-Droid metadata can be submitted. Deterministic #639 generated-client migration can continue in parallel only where schema and behavior parity are proven.
