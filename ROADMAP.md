# Pi-hole Client Maintenance Roadmap

## Objective

Maintain the fork as a conservative, upstream-compatible Pi-hole client with predictable builds, reliable Android behavior, and incremental migration toward generated Pi-hole v6 API coverage without destabilizing existing v5/v6 behavior.

## Branch / integration policy

- `main` is the canonical integrated baseline.
- The validated maintenance snapshot was merged through PR #8 on 2026-09-01; the former long-lived `dev` PR #2 was closed as superseded after content parity was verified.
- Future work must start from current `main` and use short-lived topic branches/PRs. Do not reuse stale long-lived branches as integration baselines.

## Phase 1 - Deterministic upstream maintenance

- [x] Import dependency/security maintenance that is current, reproducible and compatible with the fork.
- [x] Keep GitHub Actions/docs workflows current where upstream changes can be adopted directly.
- [x] Preserve the existing Android compileSdk 36 boundary when newer dependency majors require an unrelated SDK/AGP migration.
- [x] Keep Docusaurus/pnpm dependency remediation reproducible; do not hand-edit lockfiles.
- [x] Keep compensating controls for unpatched dependency advisories where no fixed release exists.
- [x] Import deterministic UI/docs fixes already validated upstream or in the fork.
- [ ] #442: reproduce the Android 16 popup-menu crash against current `main` on a real Android 16 device/emulator. Only implement a lifecycle-safe routing/menu fix if the current stack still reproduces it.

## Phase 2 - Device-dependent reliability

- [ ] #636: reproduce the empty Network tab after long-running use on current dependencies; capture logs/stack before changing repository/view-model behavior.
- [ ] #598: reproduce the logout/back-loop with repeated logout/back-stack sequences before altering navigation state.
- [ ] #501: validate widget display/configuration on real Android widget hosts across supported resize/layout states before changing widget layout behavior.
- [ ] #293: re-test Android authentication/secure-storage behavior on affected Galaxy devices and migration from older app versions with the currently pinned Android-compatible secure-storage dependency.
- [ ] Validate iPad-specific target/layout behavior on a real iPad before marking tablet support complete.

## Phase 3 - Pi-hole v6 API / capability migration

- [x] Establish generated Pi-hole v6 API client integration behind an adapter seam so handwritten v5/v6 behavior can coexist safely.
- [x] Migrate deterministic v6 endpoints to generated API calls incrementally with focused repository/mapper regression coverage.
- [x] Migrate Local DNS read/replacement mapping to generated models while preserving handwritten add/delete behavior where slash-containing path encoding is not specified strongly enough.
- [x] Refresh the generated OpenAPI baseline reproducibly to pinned FTL v6.7: pin FTL commit `fa65a88f8cdef1013594d4de14108077954faea4`, Redocly CLI 2.51.2, OpenAPI Generator wrapper 2.41.0 and generator 7.19.0; regenerate the client, adapt wrapper/mapper/repository/test compatibility to the v6.7 operation/model names, restore automatic Mockito regeneration for wrapper mocks, and re-audit every remaining handwritten endpoint. The remaining handwritten paths are still explicit compatibility/schema/encoding holds rather than unreviewed migration work.
- [x] Keep `/api/info/ftl` handwritten because the pinned v6.7 schema still does not model the legacy integer representation accepted by the compatibility transport.
- [x] Keep `/api/network/gateway?detailed=true` handwritten because pinned v6.7 still omits interfaces/routes from the generated gateway response despite endpoint behavior requiring them.
- [x] Keep `POST /auth` handwritten because pinned v6.7 documents TOTP but its request schema still exposes only `password`; preserve typed TOTP/rate-limit error behavior.
- [x] Keep network/ARP fallback and gravity streaming handwritten while their behavior is not represented by an equivalent generated operation.
- [ ] Remove legacy converter/mapFields helpers only after their remaining handwritten fallback callers retire; do not remove compatibility code ahead of endpoint migration.
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
  - [x] Inventory and guard the Android package-identity migration surface without choosing branding prematurely: add a parameterized audit covering Gradle namespace/applicationId, Kotlin package/path parity across main/debug/release/tests, manifest widget-action prefixes, Android display strings, launcher assets, and the Google Play packageName. Wire the current-identity audit into the existing unsigned Android PR build so future rename work fails fast on mixed/stale identity state.
  - [ ] Resolve package identity before an independent fork submission: this maintenance fork currently retains `io.github.tsutsu3.pi_hole_client`; F-Droid policy requires a fork to use a fresh Android Application ID plus corresponding name, icon and translated string changes. Use the committed identity audit during the dedicated rename, record the legacy ID as forbidden afterward, then perform the lightweight namespace collision scan before downstream metadata changes.
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
- #134 scanner compliance is resolved: Android no longer uses `mobile_scanner`/Google ML Kit. The source-build path is also isolated from private signing material and from `sqlite3` precompiled-binary downloads and is CI-validated, including an `apksigner` check that the produced release APK is unsigned. The package-identity migration surface is now inventoried and guarded in the unsigned Android PR build; a separate F-Droid publication still requires choosing and applying a fresh application ID plus corresponding name/icon/string changes before downstream metadata submission.
- GitHub Pages is enabled with GitHub Actions as the deployment source; the two latest production docs deployments from `main` completed successfully after the repository setting was corrected.
- Website dependency security maintenance remains active through Dependabot. The only currently open high-severity alerts are the two unpatched `image-size <=2.0.2` parser DoS advisories; retain the 15-minute build timeout as a compensating control and continue to resolve future lockfile changes reproducibly rather than hand-editing `pnpm-lock.yaml`.

## Completion status

**Not fully completed.** #442 remains blocked on a fresh Android 16 reproduction/current stack. #570 is implemented and CI-validated through the v6 repository and Local DNS UI layers. #134 remains the active distribution gate: secret-free unsigned packaging, Android scanner compliance and the download-free native-asset path are implemented and CI-validated, and the package-identity rename surface is now mechanically audited; the actual independent-fork application ID/name/icon decision and migration remain before downstream F-Droid metadata can be submitted. Deterministic #639 generated-client migration now runs on a reproducibly pinned FTL v6.7 OpenAPI baseline; the remaining handwritten migration work is limited to the documented compatibility/schema/behavior/encoding blockers re-audited against v6.7.
