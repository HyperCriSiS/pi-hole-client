# AI Session State

Updated: 2026-10-07

## Current baseline
- Repository: `HyperCriSiS/pi-hole-client`
- Current `main`: `1d3d62bddf375930690aeaee4485c76f0372ad99`
- Upstream auth/server-connection issue #748 remains the active architecture track.

## #748 completed slices
1. Save-attempt lifecycle / caller-owned rollback: PR #135, `417641f3`.
2. Existing-session policy probe: PR #138, `a6977e6a`.
3. Shared interactive login + blocking verification: PR #144, `6dd57ca3`.
4. Interactive-vs-background recovery policy + diagnostics: PR #146, `1d3d62bd`.
   - edit-flow TOTP cancellation is regression-locked: the target address is marked `reauth-declined` before immediate auto-refresh resumes;
   - successful interactive edit clears that marker;
   - background `handleTotpReauth` refuses to reopen TOTP after user cancellation;
   - suppressed automatic TOTP recovery is recorded through the shared redacting App Log diagnostic path;
   - `AppConfigViewModel.addDiagnostic` delegates to `AppLogService.addDiagnostic`;
   - `docs/server-connection-flow.md` now documents the implemented policy rather than the obsolete double-prompt behavior.

## Policy boundaries that must remain stable
- `ProbeExistingSession`: valid SID reuse vs auth-required vs transient failure.
- `runInteractiveConnectionCheck`: explicit user-interactive login/TOTP + blocking verification.
- `_SaveAttempt` / caller: credentials, SID rollback/restore/commit/cleanup ownership.
- PR #129 `refreshWithTotpRecovery`: explicit user-triggered refresh recovery; do not make initial/automatic/background loads prompt interactively.
- A user-cancelled TOTP recovery suppresses automatic re-prompting until a later successful interactive connection clears the marker.

## Validation for slice 4
Repository-controlled gates passed on PR #146:
- full Dart tests
- unsigned Android source APK + unsigned-artifact verification
- docs deployment test
- CodeQL
- static analyses

The separate GitHub-managed `github-advanced-security` AI-agent job failed independently because the monthly Copilot quota is exhausted (HTTP 402); this is not a repository finding.

## Next autonomous work block
1. Re-read live `main`, `ROADMAP.md` and `UPSTREAM_TRIAGE.md`.
2. Continue #748 only if a bounded remaining duplication/policy gap is identifiable; do not collapse the established boundaries above.
3. Audit authentication/reconnect diagnostics for remaining screen-local/manual `AppLog` construction and migrate only clear duplicates to the shared diagnostic entry point.
4. Preserve #129 explicit-refresh semantics and the reauth-declined suppression contract.
5. Add focused tests before broad refactors; validate repository-controlled gates before merge.

## Existing holds
- #442: Android 16 PopupMenu device confirmation required.
- #636: Android 17 self-signed HTTPS reproduction/App Log required.
- #501: widget density/layout device validation required.
- #293: secure-storage/auth device migration validation required.
- #134: independent-fork product identity decision blocks final F-Droid rename/submission.
- #639: handwritten holds remain `/api/info/ftl`, detailed network gateway and gravity streaming for documented schema/behavior reasons.

## Resume protocol
1. Read this file, `ROADMAP.md` and `UPSTREAM_TRIAGE.md` from `main`.
2. Resolve live `main` and confirm it is at or beyond `1d3d62bd`.
3. Confirm there is no competing open feature PR before starting the next slice.
4. Continue #748 with a bounded diagnostics/reconnect cleanup only if it removes clear duplication without changing interactive-vs-background behavior.
5. Keep explicit user-interactive TOTP recovery separate from initial/automatic/background flows.
6. Keep device-gated #442/#636/#501/#293 validation-only until affected-device evidence exists.
7. Validate repository-controlled gates before every merge.
