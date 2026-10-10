# AI Session State

Updated: 2026-10-10

## Current integrated baseline

- Repository: `HyperCriSiS/pi-hole-client`. `main` is the canonical integration branch; use task-specific branches and PRs with exact-HEAD checks.
- **Latest validated application merge:** upstream #766 credential-read safety fix, PR #183 squash `c14069103475160356d7e88be7643958c9da584e`, final feature HEAD `8fc0be0c4df7ca42b8d615d99f2a1ca44473ca1d`.
- Other #720 completed slices:
  - PR #176 Server Info: `6728a230156ff1f1e30174f68c0599cd6de892da` (HEAD `2d4f1eeb`). Preserves last good server data/capabilities, progress indicator, stale-data warning after failure; initial skeleton/error states unchanged.
  - PR #177 DHCP leases: `2b60914a087ae9b7746bc327b03811626b87d50b` (HEAD `9fa28613`). Successful leases/client IP retained during manual refresh; progress/stale warning; successful-empty tracked separately from initial placeholder; duplicate refresh disabled.
  - PR #178 Network devices: `d610ad8ecf700ef4e79bf072240b3920541c183e` (HEAD `0b8a731a`). Equivalent bounded Network-device refresh preservation.
- All three feature PR HEADs passed full Dart tests, Sonar, Codecov, CodeQL, static analyses, unsigned Android source APK build and **Verify unsigned release artifact** before merge. No live Pi-hole/server/device smoke is claimed.
- PR #179 docs/upstream audit merged as `c7110c81906c511630ef4336375e0cd96601fb50`: `docs/maintenance/upstream-credential-load-2026-10-10.md`, plus compact session checkpoint. GitHub Issues are disabled in this fork (HTTP 410).

## Completed architecture foundations / boundaries

- #748 fork auth/session recovery completed via #135 SaveAttempt rollback, #138 existing-session probe, #144 shared interactive login/verification, #146 interactive-vs-background recovery / declined TOTP marker, #148 centrally redacted diagnostics. Upstream #748's open status does not make the fork implementation incomplete.
- Explicit user-triggered refresh/TOTP recovery uses `refreshWithTotpRecovery` (#129). Background/initial loads must not prompt or create retry loops. Preserve owner-controlled secrets/SID rollback and central redaction.
- Connection Doctor complete in bounded slices: #152 read-only server capabilities/TLS/session state, #170 timing of existing FTL batch, #172 conditional Gravity/nginx buffering hint, #174 manually triggered v6 endpoint checks. No synthetic ping, duplicate authentication or raw diagnostic secrets.
- Upstream #724 stale Group/Client delete detail fixed in #166; #718 failed-load notifier/retry in six settings ViewModels fixed in #168.
- Pinned FTL v6.7 OpenAPI generation and boundary guard restrict remaining handwritten transport to documented `/api/info/ftl`, detailed `/api/network/gateway`, and gravity streaming holds.
- `sqlite3` deliberately bounded to `>=3.5.2 <3.6.0` until the Flutter baseline permits `meta ^1.19.0`; do not force overrides or relax F-Droid native source-build policy.

## Security update: upstream #766 resolved in fork (P1)

- **Completed PR #183:** distinguished legitimately absent secure values from read failures using secret-free typed exceptions; `fetchCredentials` now propagates real token/password read errors, while optional missing values remain valid.
- Edit Save is disabled before successful credential loading and after read failure; a localized error/explicit retry does not destroy existing draft fields on failure. Success clears the lock. Preserved #748 `secretsLoadSucceeded` rollback safeguard and existing session/TOTP boundaries; no additional authentication flow.
- Final PR HEAD `8fc0be0c` passed full Dart tests including new repository/UI regressions, CodeQL, Sonar, Codecov, static checks, unsigned Android source build and artifact verification. No affected physical-device keystore failure was reproduced. Detailed history: `docs/maintenance/upstream-credential-load-2026-10-10.md`.
- Relevant upstream merge cursor: `b3c940460ba7f25e7ef2fd0328fc91b2ed0a2abe` (#766); upstream #767 generated code still held for generator parity, #768 copyright/privacy docs pending independent-fork review.
- Previous upstream cursor `445424380076d09293ca1a2ce638d6f144e27233`; reviewed new cursor `b3c940460ba7f25e7ef2fd0328fc91b2ed0a2abe`. Upstream #768 policy/copyright only needs independent-fork review; #767 generated-code changes need pinned generator parity.

## Remaining roadmap and external validation

1. **Next:** batch remaining #720 Settings revalidation for Sessions, Interfaces, Local DNS into a coherent UI PR with retained loaded content, lightweight explicit-refresh progress and failure/retry regressions. Keep initial loads separate and preserve #748 TOTP boundaries.
2. Continue #720 loading/revalidation across Sessions, Local DNS, Interfaces and other screens after preserving first-load skeletons, manual cached refresh and nonblocking background behavior. Do not mark #720 globally complete yet.
3. Then evaluate power-user roadmap: multi-Pi-hole dashboard, cross-server quick actions, saved Log Explorer filters and OpenAPI-spec drift reporting.
4. Optional separate smoke: `mock_api_server --fail all` / `--fail auth/sessions`, real-server Gravity/proxy diagnostics; lack of reproduction is not resolution.
5. Device/distribution holds: #442 Android 16 PopupMenu; #636 Android 17 self-signed TLS with App Log; #501 tablet/widget layout; #293 secure-storage migration; #686 keyboard layout; #741 Android 17 Impeller/Vulkan; #134 final independent application ID/name/icon and F-Droid publication.
6. Maintain full Dart, unsigned Android artifact/signature verification, static analyses, Sonar, Codecov and CodeQL checks for application changes on the exact final HEAD. Docs-only changes can use the repository's lighter workflow.

## Fork identity archival and throughput decision (2026-10-10)

- User preference: hold independent app branding/publication while exploring collaboration with active upstream maintainer. Do not further develop app-ID migration tools unless a separate release is explicitly approved.
- Optional toolkit relocated from `tools/identity/` to `tools/archive/fork-identity/`: app identity config/audit, migration, local F-Droid App ID collision checker and both standalone tests. This tooling is parked and should not run on every Android PR.
- The active F-Droid-compatible source-build path, free QR scanner, `tools/prepare_fdroid_source_build.dart`, and unsigned APK/artifact verification are **not** archived or disabled.
- Speed-up policy: batch related low-risk UI changes into one tested PR rather than separate full builds, run focused checks before pushing, retain the final exact-HEAD gates, skip archived/docs-only PRs in expensive Flutter/Android CI, and avoid repeated no-op CI polling. Do not bundle credential/security changes with UI or platform migration.
- Completed in PR #181 (squash `e88b27aa1c9f30d61d064749b61247b686c766ab`): 9/9 archived Python tests passed locally; exact-HEAD Dart tests, Sonar, Codecov, CodeQL, static analyses, documentation validation, unsigned Android source APK build and **Verify unsigned release artifact** passed before merge. No runtime Pi-hole/device smoke claimed.

## Resume instructions

Read this file, root `ROADMAP.md` (authoritative), `UPSTREAM_TRIAGE.md`, `AGENTS.md` and relevant architecture before starting; verify live `main`/open PR/CI status. Keep commits and CI queries targeted, no tight polling. Prefer a fresh conversation when tool history grows; add a compact checkpoint after larger finished work.
