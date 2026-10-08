# AI Session State

Updated: 2026-10-08

## Current baseline
- Repository: `HyperCriSiS/pi-hole-client`
- Current `main`: `524a1fe449c4dd7b6eac24a4ccd847b337490e45`
- Upstream auth/server-connection issue #748 remains open upstream, but the fork roadmap work is complete.

## #748 completed slices
1. Save-attempt lifecycle / caller-owned rollback: PR #135, `417641f3`.
2. Existing-session policy probe: PR #138, `a6977e6a`.
3. Shared interactive login + blocking verification: PR #144, `6dd57ca3`.
4. Interactive-vs-background recovery policy: PR #146, `1d3d62bd`.
   - edit-flow TOTP cancellation marks the address reauth-declined before immediate auto-refresh resumes;
   - background recovery respects that marker and does not reopen the prompt;
   - a later successful interactive connection/edit clears the marker.
5. Shared connection diagnostics: PR #148, `98aae46f`.
   - `ServerConnectionService` no longer constructs `AppLog` entries locally;
   - connection/auth/secure-storage diagnostics use `AppConfigViewModel.addDiagnostic` -> `AppLogService.addDiagnostic`;
   - focused coverage verifies credential-shaped text is still centrally redacted.

## Upstream sync 2026-10-08
- Reviewed upstream `tsutsu3/pi-hole-client` through `445424380076d09293ca1a2ce638d6f144e27233`.
- Imported upstream #756 and #763 selectively through fork PR #150, merged as `dcffeafe`.
  - #756: full server-address validation plus add/edit save-error recovery so the Connecting overlay cannot remain stuck on an unexpected command failure.
  - #763: group-load failures during screen initialization are caught and logged rather than surfacing as unhandled/Sentry errors.
- Upstream #749 needs no duplicate import because equivalent widget replacement/removal synchronization is already present in the fork.
- Upstream #760 is intentionally not imported wholesale because it crosses proven Flutter/Dart/Android/F-Droid compatibility boundaries; compatible dependency updates remain selective.
- Upstream #765 is formatting-only and needs no import.
- PR #150 validation passed: full Dart tests, unsigned Android source APK + artifact verification, CodeQL, Sonar, Codecov and static analyses.

## Connection Doctor progress
- Slice 1 merged via PR #152 as `71b667b2`.
- Server Info now exposes a read-only per-server summary for:
  - configured API version and reported FTL version;
  - resolved API base path and web-panel path, including existing reverse-proxy prefix/webhome capability;
  - MFA capability;
  - current v6 session state from the already-shared in-memory session cache;
  - configured TLS/certificate policy.
- The session diagnostic getter is side-effect-free: it does not read secure storage, make a network request, renew a SID, authenticate or open TOTP UI.
- Existing #748 auth/recovery boundaries remain unchanged.
- PR #152 validation passed: full Dart tests, unsigned Android source APK + unsigned-artifact verification, v6 legacy-boundary audit, CodeQL, Sonar, Codecov and static analyses.

## Stable policy boundaries
- `ProbeExistingSession`: valid SID reuse vs auth-required vs transient failure.
- `runInteractiveConnectionCheck`: explicit user-interactive login/TOTP + blocking verification.
- `_SaveAttempt` / caller: credentials, SID rollback/restore/commit/cleanup ownership.
- PR #129 `refreshWithTotpRecovery`: explicit user-triggered refresh recovery only.
- Initial/automatic/background loads must remain non-interactive unless they enter the shell-level guarded recovery path.
- A user-cancelled TOTP recovery suppresses automatic re-prompting until a later successful interactive connection clears the marker.

## Validation
Repository-controlled gates passed for the final #748 slice:
- full Dart tests
- unsigned Android source APK + unsigned-artifact verification
- CodeQL
- static analyses

The separate GitHub-managed `github-advanced-security` AI-agent job failed independently because the monthly Copilot quota is exhausted (HTTP 402); this is not a repository finding.

## Next autonomous work block
1. Re-read live `main`, `ROADMAP.md` and `UPSTREAM_TRIAGE.md`.
2. Continue **Connection Doctor** with one bounded read-only slice:
   - add explicit endpoint reachability/latency diagnostics without exposing secrets;
   - reuse the existing server URL/TLS policy and shared repositories/transport where practical;
   - do not create a second authentication/recovery policy or automatic TOTP prompt path.
3. Keep actionable proxy/streaming hints such as #754 as the following separate slice after reachability/latency is stable.
4. Keep #720 loading/revalidation UX after Connection Doctor's deterministic diagnostics.
5. Keep device-gated items validation-only until affected-device evidence exists.

## Existing holds
- #442: Android 16 PopupMenu device confirmation required.
- #636: Android 17 self-signed HTTPS reproduction/App Log required.
- #501: widget density/layout device validation required.
- #293: secure-storage/auth device migration validation required.
- #134: independent-fork product identity decision blocks final F-Droid rename/submission.
- #639: handwritten holds remain `/api/info/ftl`, detailed network gateway and gravity streaming for documented schema/behavior reasons.

## Resume protocol
1. Read this file, `ROADMAP.md` and `UPSTREAM_TRIAGE.md` from `main`.
2. Resolve live `main` and confirm it is at or beyond `524a1fe4`.
3. Re-audit upstream changes after `445424380076d09293ca1a2ce638d6f144e27233`, then confirm there is no competing open feature PR before starting a new slice.
4. Treat #748 as complete in the fork unless a concrete regression or upstream change creates a new bounded gap.
5. Prefer a fresh chat for the next larger unit if GitHub/CI tool history has become substantial.
6. Validate repository-controlled gates before every merge.

## Dependency maintenance checkpoint (2026-10-08)
- Website dependency update PR #140 merged as `f9df81b6` (website deployment test passed).
- `go_router` 18.0.2 PR #143 merged as `ab954bb1`.
- `cupertino_icons` 2.0.0 PR #142 merged as `524a1fe4`.
- `sqlite3` 3.7.0 PR #141 was closed: Flutter 3.44.1 pins `meta 1.18.0`, while sqlite3 >=3.6.0 requires `hooks ^2.2.0` -> `record_use >=1.0.0` -> `meta ^1.19.0`.
- Replacement PR #153 merged as `34ad56f5`: bound `sqlite3` to `>=3.5.2 <3.6.0` and ignored only proven-incompatible 3.6.0 / 3.7.0 in Dependabot.
- PRs #142 and #153 passed full Dart tests, Android unsigned APK build, CodeQL, Sonar, Codecov and static checks; #153 also passed Dependabot config validation.
- No known GitHub Advisory Database vulnerabilities found for the retained `sqlite3 3.5.2`, `cupertino_icons 2.0.0` or `go_router 18.0.2` when checked.
- Revisit the sqlite3 upper bound and exact Dependabot ignores when a validated Flutter baseline supports `meta ^1.19.0`; never force the dependency with overrides.

## Dependency maintenance follow-up (2026-10-08)
- Dependabot PR #158: `url_launcher` 6.3.2 -> 6.3.3, merged as `dc84ce2c`.
- Dependabot PR #159: `package_info_plus` 10.2.1 -> 10.2.2, merged as `b5b6ae7e`.
- Dependabot PR #160: `device_info_plus` 13.2.0 -> 13.3.0, merged as `f2674e16`.
- Each Dependabot-generated lockfile initially contained newer Flutter-SDK-pinned transitives (`intl`, `matcher`, `meta`, `test_api`, `vector_math`); these were aligned with the Flutter 3.44.1 baseline.
- The follow-up CI failures were caused solely by a missing final newline in `pubspec.lock`. All three files were corrected; PR diffs then contained only their direct dependency upgrades.
- Each PR passed full Dart tests, CodeQL, Sonar, Codecov, static analysis and unsigned Android source APK build before squash merge.
- GitHub Advisory Database check found no known advisories for these three updated versions at the time of review.
- Any future Dependabot pub PR must verify SDK-pinned transitive resolution and `pubspec.lock` stability; do not bypass the strict lockfile check.

## Upstream issue gap audit (2026-10-08)
- No upstream issue created or updated since the current upstream review cursor; reviewed older upstream reports missing from fork triage.
- Added **#724** (Group/Client stale tablet detail after delete) and **#718** (settings load error leaves skeleton indefinitely) as P1 deterministic follow-ups in `ROADMAP.md`. Upstream fixes #725/#721 serve as references, not wholesale imports.
- Added **#741** (Android 17 Impeller/Vulkan crash on Flutter 3.44.1) and **#686** (Android IME/bottom-sheet resume layout) as P2 affected-device validation holds; no unverified framework/platform workaround.
- Verified **#722** same-IP Local DNS targeting already uses `oldRecord`/`newRecord` with full record equality; no duplicate implementation.
- **#699** website image quality has no proven equivalence across the fork/upstream docs stacks; not committed as an app blocker.
- Triage also records upstream dependency PR #764 as selective: fork already integrated its compatible packages while Android 37/`dynamic_color` major blockers remain.
- Next bounded implementation order: #724, #718, then resume Connection Doctor; device-gated issues await repro evidence.
