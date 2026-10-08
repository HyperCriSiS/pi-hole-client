# AI Session State

Updated: 2026-10-08

## Current baseline
- Repository: `HyperCriSiS/pi-hole-client`
- Current `main`: `71b667b203641694817e0080f3fbb37e736407a5`
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
2. Resolve live `main` and confirm it is at or beyond `71b667b2`.
3. Re-audit upstream changes after `445424380076d09293ca1a2ce638d6f144e27233`, then confirm there is no competing open feature PR before starting a new slice.
4. Treat #748 as complete in the fork unless a concrete regression or upstream change creates a new bounded gap.
5. Prefer a fresh chat for the next larger unit if GitHub/CI tool history has become substantial.
6. Validate repository-controlled gates before every merge.
