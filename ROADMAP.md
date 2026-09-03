# Roadmap

Last updated: 2026-08-30

## Context

Maintain and improve the unofficial Pi-hole client while upstream activity is limited, with explicit safeguards for Android 16/17 behavior, Pi-hole v5/v6 compatibility, F-Droid reproducibility, release readiness, and efficient future hand-off.

## Phase 0 - Baseline and Release Understanding

### Repository and release baseline

- [x] Map repository structure and package boundaries.
- [x] Review open issues and open pull requests relevant to maintenance readiness.
- [x] Review the tagged release history and the current `main` baseline.
- [x] Confirm that the current public release line is `1.9.2`, with `2.0.x` previously attempted but not active as a stable release line.
- [x] Confirm `main` as the canonical maintenance baseline after validating and integrating the framework-audited snapshot through PR #8; the historical long-lived `dev` branch is now legacy-only and future integration should use short-lived branches/PRs from `main`.
- [x] Record the current CI/release pipeline assumptions before changing them.
- [x] Harden GitHub Actions workflows with explicit least-privilege `GITHUB_TOKEN` permissions; `permissions: read-all` was removed from `test.yaml`, `test-deploy-docs.yaml`, `release.yaml`, `dependabot.yaml`, and `store-badges.yml`, while the Pages deploy retains only `pages: write` and `id-token: write` for the deploy job.
- [x] Remove the accidentally committed local `log-details-context.txt` diagnostic artifact from repository history going forward; repository-wide secret scanning reported no credential matches in the removed log snapshot or current workflow/configuration surfaces.
- [x] Extend Dependabot coverage to the isolated `/website` npm ecosystem in addition to the root Pub and GitHub Actions ecosystems; the website lockfile currently contains vulnerable transitive build dependencies and now has automated update coverage.
- [x] Stabilize mandatory repository CI by validating the standalone `mock_api_server` package independently, excluding it from the root analyzer package walk, generating `lib/build_info/git_commit.dart` before Android source builds, pinning the docs workflow's pnpm version, and making Codecov/Sonar upload steps optional when their repository secrets are unavailable.
- [x] Validate the final integration candidate `746db758b65ba1aa026f2cf45290027082b4c831` through the project-side release-candidate gate (Dart tests, unsigned Android source APK, docs validation, CodeQL, Codecov, Sonar, and static analysis all green); the separate GHAS agent failure is caused by GitHub's unavailable `claude-opus-4.6` model rather than a project code finding.
- [x] Merge PR #8 (`Integrate validated maintenance snapshot`) from the immutable audit candidate into `main`, preserving the full maintenance history instead of squash-rewriting it.
- [x] Close the old `dev` maintenance PR #2 as superseded after verifying that all 46 root Git tree entries on `dev` and the integrated `main` snapshot were byte-identical despite historical merge divergence.
- [x] Isolate the post-integration roadmap normalization on a short-lived branch/PR from `main`; preserve historical `dev` references where they describe past work, but use current `main` for all future baselines and device reproductions.
- [x] Harden Dependabot version-update grouping so Pub, npm, and GitHub Actions major updates are no longer mixed into broad maintenance batches; review breaking majors independently, and keep Pub/Dart dependency updates fully ungrouped because Dependabot currently does not reliably honor group update-type restrictions for the Pub ecosystem.
- [x] Validate the Docusaurus 3.10.2 upgrade plus targeted same-major/same-line pnpm overrides for `browserslist 4.28.8`, `nanoid 3.3.18`, `js-yaml 4.3.1`, `fast-uri 3.1.5`, `postcss 8.5.18`, `svgo 3.3.4` and `brace-expansion 1.1.18`; all patchable website High alerts are remediated and only the two currently unpatched `image-size 2.0.2` parser DoS advisories remain, bounded by 15-minute docs-build timeouts until upstream publishes a fix.
- [x] Enable repository GitHub Pages with `Source = GitHub Actions`; production deployments from `main` now complete successfully, so Pages is no longer an external configuration blocker.

### Framework-derived completion gate

- [x] Re-run targeted full-suite tests before declaring maintenance work complete.
- [x] Re-run `dart analyze` after API/model migrations.
- [x] Verify no accidental debug artifacts or credentials are committed.
- [x] Confirm the validated maintenance snapshot is integrated into `main` through a reviewed PR instead of remaining isolated on a long-lived branch.
- [x] Keep the validation gate green on `main` after integration by validating all mandatory project-side checks on each short-lived follow-up PR.
- [x] Keep npm/website dependency remediation explicit: all currently patchable High alerts are cleared; the remaining two `image-size 2.0.2` parser DoS advisories have no upstream patch yet and remain covered by bounded 15-minute docs builds until a patched release is available.
- [ ] Update user-facing release notes if a new public build is produced.
- [ ] Re-check store/F-Droid implications before any public release.

## Phase 1 - Test Harness and Regression Safety

### Test coverage foundation

- [x] Verify the existing unit and widget test topology under `test/`.
- [x] Identify missing regression coverage around reported platform failures.
- [x] Add focused regression tests for changed behavior before/with fixes where practical.
- [x] Add request-parity coverage for generated v6 endpoints before removing handwritten transport logic.
- [ ] Add/refresh Android 16/17 device or emulator smoke coverage for lifecycle-sensitive UI where reproducible.
- [x] Keep deterministic CI gates for repository-side checks; local validation remains useful when available but must not become a dependency for completion.

### Priority regression matrix

- [ ] Android 16 popup/dialog lifecycle path (`#442`).
- [ ] Android 17 authentication/connectivity path (`#636`).
- [ ] Widget no-data rendering (`#598`).
- [ ] Secure storage migration/non-destructive read path (`#293`).
- [ ] Generated Pi-hole v6 API request/response parity for each migrated endpoint (`#639`).
- [x] v6 CNAME CRUD/compatibility path (`#570`).

## Phase 2 - Android 16/17 Compatibility

### Android 16

- [ ] Reproduce current popup/dialog crash on the current `main` baseline rather than the historical 1.9.2 stack trace alone.
- [ ] Reproduce on an Android 16 emulator/device if practical.
- [ ] Confirm whether the original Flutter lifecycle/assertion path still exists on the current Flutter dependency set.
- [ ] Add a minimal regression test or code-level lifecycle guard once the current trigger is confirmed.
- [ ] Verify normal show/dismiss/background/foreground flows after the fix.
- [ ] Only declare `#442` resolved after fresh reproduction evidence or an explicit non-reproduction record on the current stack.

### Android 17

- [ ] Reproduce Pi-hole connection/auth failure on Android 17.
- [ ] Compare Android 16 vs Android 17 network/security behavior.
- [ ] Check cleartext/TLS/network-security configuration assumptions.
- [ ] Verify HTTP/S, self-signed certificate, and normal authenticated server flows.
- [ ] Retest with current Flutter/network stack before introducing workarounds.

## Phase 3 - Pi-hole v6 Generated API Migration (`#639`)

### Migration strategy

- [x] Inventory handwritten HTTP calls in `PiholeV6ApiClient`.
- [x] Classify endpoints by migration risk: trivial, model-sensitive, special behavior, streaming.
- [x] Add wrapper/service support around generated OpenAPI clients without forcing domain-layer rewrites.
- [x] Migrate low-risk endpoints incrementally.
- [x] Migrate list/search and gravity/mutation reads after validating request/response parity; retain handwritten gravity streaming because the generated client does not expose streamed progress semantics.
- [x] Migrate list-management CRUD (`GET/POST/PUT/DELETE /api/lists/{list}`) after verifying generated schemas preserve `list`, `type`, list IDs and group assignments; keep domain mapping unchanged by round-tripping generated responses into the existing transport model.
- [x] Migrate config read/write (`GET/PATCH /api/config`) after verifying generated `Config` parity for the nested DHCP, DNS, resolver, hosts, NTP and misc fields currently consumed by the client; preserve SID renewal/retry semantics and keep the existing transport/domain mapper by round-tripping generated JSON into the legacy config model.
- [x] Migrate `/api/info/system` after verifying generated-schema parity for uptime, memory, process and CPU/load fields; preserve compatibility with pre-FTL-6.1 payloads where `%cpu` is absent, and route SID handling through the generated service.
- [x] Migrate `/api/info/host` after verifying parity for uname, model and DMI payloads; keep the existing domain mapper by round-tripping the generated response into the proven legacy transport model, with focused SID/error regression coverage.
- [x] Migrate `/api/info/messages` read/delete after verifying parity for message IDs, timestamps, types, plain/HTML payloads and delete semantics; preserve existing message-domain filtering while routing SID/error handling through the generated service.
- [x] Migrate `/api/history` activity metrics to the generated service after verifying parity for timestamps and total/cached/blocked/forwarded counters; preserve the proven domain mapper by round-tripping the generated response through the legacy transport model, and keep shared SID renewal/retry behavior under focused regression coverage.
- [x] Migrate `/api/history/clients` after adding `N`/count forwarding to `PiholeV6Service`; preserve default/custom/omitted count semantics, response-model parity, shared SID renewal/retry handling and focused wrapper/repository regression coverage.
- [ ] Keep `/api/info/ftl` on the handwritten client for now: the generated schema models v6.3 domain/regex counters only as `{total, enabled}` objects, while the existing transport model intentionally accepts the v6.2 integer representation as well.
- [x] Migrate `/api/network/devices/{device_id}` deletion to the generated service with shared SID/retry handling and focused error/ID regression coverage.
- [x] Migrate `/api/network/devices` reads after extending the generated-service wrapper to preserve the existing `max_devices`/`max_addresses` limits; focused repository and wrapper tests verify SID handling, default/custom limit forwarding, response parity and failures.
- [ ] Keep `/api/network/gateway` on the handwritten client unless the generated schema is corrected or a compatibility layer is added: current code needs optional per-interface gateway maps (`Map<String,String>`), while the generated model only exposes scalar `String?` gateways.
- [ ] Keep `/api/auth` on the handwritten client until generated/auth domain parity is complete for TOTP-required/invalid login outcomes, multi-step credential submission, and app-specific auth error mapping; session-list/read/delete flows may remain separate low-risk candidates.
- [ ] Keep `/api/info/client` on the handwritten client until the generated model restores the existing `proto_version` field; dropping it would be a domain regression even though the rest of the payload is schema-compatible.
- [ ] Keep `/api/network/gateway` and auth out of the low-risk migration queue until their documented schema/behavior blockers are resolved.
- [ ] Preserve handwritten ARP/network fallback behavior while generated network parity remains incomplete.
- [ ] Preserve gravity streaming where generated clients cannot expose streamed progress semantics.
- [x] Remove redundant handwritten paths only after request/response and auth parity are verified.

### Verification per migrated endpoint

- [x] Request parameters match current behavior.
- [x] SID/auth handling matches current behavior.
- [x] Response mapping remains compatible with existing domain models.
- [x] Error semantics remain compatible.
- [x] Tests cover success and failure paths.

## Phase 4 - Widgets and Background Behavior

### Widget data reliability (`#598`)

- [ ] Trace widget refresh from scheduler/service through persistence to render state.
- [ ] Distinguish "no data", "not authenticated", and "refresh failed" states.
- [ ] Add timeout/error fallback behavior if missing.
- [ ] Test process-death/background-refresh behavior.

### Android process/lifecycle hardening

- [ ] Audit background task assumptions against modern Android restrictions.
- [ ] Check widget refresh after reboot, app update, and force-stop recovery.
- [ ] Avoid adding persistent background work unless required by user-visible behavior.

## Phase 5 - Secure Storage and Credential Migration (`#293`)

### Storage upgrade safety

- [ ] Reproduce migration paths from older app versions/storage backends.
- [ ] Verify reads do not destructively delete recoverable credentials.
- [ ] Validate Android backup/restore interactions where applicable.
- [ ] Add migration tests around empty/legacy/corrupt values.
- [ ] Document any one-way migration behavior before release.

## Phase 6 - F-Droid Readiness (`#134`)

### Reproducible release path

- [x] Add a separate source-build validation path that compiles a release APK from tracked source without repository signing credentials and verifies the produced artifact is unsigned.
- [x] Add a strict F-Droid scanner path on source artifacts that treats scanner violations as blocking; skip only fork/non-free-only dependency exclusions while keeping the production Play-store workflow unchanged.
- [x] Remove direct `mobile_scanner`/Google ML Kit barcode scanning from the production dependency graph and replace QR import with a FLOSS-native ZXing2 camera-frame decoder; restore Android camera permission flow and lifecycle-safe scanning without proprietary ML Kit artifacts.
- [x] Raise the Android app build SDK line to `compileSdk = 36` / `targetSdk = 36`, migrate to the stable Flutter 3.44.1 toolchain, and keep Android Gradle Plugin 8.11.1 on the last AGP 8 line rather than introducing AGP 9 compatibility risk before release readiness is established.
- [x] Establish the intended F-Droid application identity without affecting the existing Play application ID: source builds use `io.github.tsutsu3.pi_hole_client` via `-PfdroidBuild=true`, while normal builds/releases retain `io.github.tsutsu3.pi_hole_client_google` for Play upgrade compatibility.
- [ ] Verify clean source-only build from a fresh checkout.
- [x] Remove or isolate non-FOSS dependencies/services from the F-Droid variant while preserving Play-store behavior in the normal variant.
- [x] Keep signing material out of the source-only pipeline and verify the produced release APK has zero signers.
- [ ] Add F-Droid metadata after package identity/name/icon/translations are final.

### F-Droid manifest and branding

- [ ] Decide final app name/summary/description for F-Droid.
- [ ] Verify launcher icon and branding assets.
- [ ] Verify Fastlane/metadata layout if used.
- [ ] Confirm screenshots and changelog strategy.

## Phase 7 - CI/CD and Release Hardening

### CI quality gates

- [x] Ensure tests and analysis run on pull requests.
- [x] Add Android source-build validation independent of Play signing secrets.
- [x] Add strict F-Droid scanner validation and artifact retention.
- [x] Add generated-API parity tests where migration work lands.
- [x] Add automated source-APK verification that fails if repository signing material becomes visible to the source-build path or if the resulting release artifact has a signer.
- [ ] Add targeted Android platform smoke coverage where practical.

### Release workflow

- [ ] Verify production release path separately from source-only/F-Droid path.
- [ ] Confirm version-code/version-name handling remains compatible with installed Play builds.
- [ ] Confirm release assets and changelog generation.
- [ ] Confirm no deployment/publish step can run from untrusted PRs.

## Phase 8 - Documentation and Handover

- [x] Keep `ROADMAP.md` as the implementation source of truth during maintenance.
- [x] Maintain a public Docusaurus documentation surface under `website/` with GitHub Pages deployment driven only from trusted `main` changes once repository Pages is enabled; production deployment is now verified green.
- [ ] Document local development/build prerequisites after the dependency/toolchain changes settle.
- [ ] Document Pi-hole v5/v6 support expectations.
- [ ] Document Android platform support expectations.
- [ ] Document known limitations that remain intentionally unfixed.
- [ ] Record verification commands and release steps for future maintainers.

## Exit Criteria

Maintenance work is ready for a release candidate when:

- [ ] Current blocking Android 16/17 issues are resolved or explicitly documented with reproducible evidence.
- [ ] Current `main` passes tests and analysis.
- [x] Generated v6 API migration is expanded only where parity is proven.
- [x] F-Droid source-build constraints are documented and validated where changes landed.
- [ ] Secure-storage migration risk is understood and covered.
- [x] Roadmap, CI, release intent, and remaining blockers are documented.
