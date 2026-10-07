# AI Session State

Updated: 2026-10-07

## Current baseline
- Repository: `HyperCriSiS/pi-hole-client`
- Current `main`: `98aae46fed9f62019357997409695fb1e89a38be`
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
2. Start the next roadmap item as a fresh bounded unit; do not reopen #748 without a concrete regression.
3. Preferred next deterministic architecture item: **Connection Doctor**.
   - expose per-server capability/diagnostic information already available without secrets;
   - begin with a read-only model/view slice, not transport rewrites;
   - preserve all #748 auth/recovery boundaries above.
4. Keep #720 loading/revalidation UX after connection/session architecture stable.
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
2. Resolve live `main` and confirm it is at or beyond `98aae46f`.
3. Confirm there is no competing open feature PR before starting a new slice.
4. Treat #748 as complete in the fork unless a concrete regression or upstream change creates a new bounded gap.
5. Prefer a fresh chat for the next larger unit because the current conversation contains substantial GitHub/CI history.
6. Validate repository-controlled gates before every merge.
