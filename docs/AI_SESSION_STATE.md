# AI Session State

Updated: 2026-10-10

## Live integrated baseline

- Repository: `HyperCriSiS/pi-hole-client`; canonical integration branch `main`.
- **Latest application merge: PR #185**, squash `ad1a19411dd7e080d975d13a9f7151ec9ff012e3`, final tested HEAD `89b951552406d5c55be77bf4658e9ad7ea407362`.
- #720 Settings revalidation completed in bounded slices:
  - PR #176 Server Info `6728a230`.
  - PR #177 DHCP leases `2b60914a`.
  - PR #178 Network devices `d610ad8e`.
  - **PR #185 Sessions, Interfaces and Local DNS `ad1a1941`**: retain successful contents (including successful-empty state) through manual refresh and failed revalidation; progress bar and translated stale-data warning; initial skeleton/error states stay; avoid overlapping refreshes. Existing Sessions deletion, Interfaces details, Local DNS host/CNAME and explicit TOTP recovery are preserved. New ViewModel/widget regressions cover failure and retry.
- All #185 checks passed against **exact HEAD**: full Dart test/analyzer job, Sonar, Codecov, CodeQL, four static analysis jobs, unsigned Android source APK build, and successful `Verify unsigned release artifact` step in workflow run `38069751644` / test run `38069751633`. No live Pi-hole/device smoke claimed.
- **#720 is not globally complete**: the six identified Server Settings surfaces are done, but other loading/background behavior and UX consistency remain for separate assessment.

## Security and auth boundaries

- **Upstream #766 credential read safety is fixed**, PR #183 squash `c14069103475160356d7e88be7643958c9da584e`, tested feature HEAD `8fc0be0c4df7ca42b8d615d99f2a1ca44473ca1d`; recorded in PR #184 and `docs/maintenance/upstream-credential-load-2026-10-10.md`. True secure-storage read failure cannot become an absent password/token; the edit Save action remains disabled on load failure until a successful explicit retry; missing optional values remain allowed. Diagnostic secrets stay redacted. Dart, Sonar, Codecov, CodeQL, statics, unsigned APK and artifact verification passed. Device-specific keystore error not yet reproduced.
- #748 complete in fork: PR #135 caller-owned credential/SID rollback; #138 existing-session probe; #144 shared interactive login/TOTP verification; #146 background-vs-interactive retry/decline policy; #148 centrally redacted App Log.
- Explicit user-triggered refresh recovery uses `refreshWithTotpRecovery` (#129). Initial/automatic/background loads must not open interactive TOTP or create prompt loops. Avoid changing #748, `_SaveAttempt` or redacted logging as incidental edits.
- Connection Doctor completed via PR #152 read-only capability/TLS/session summary, #170 FTL batch timing, #172 conditional Gravity/nginx streaming hint, #174 manually requested per-endpoint diagnostics. No duplicate probe/auth, no raw credential or untrusted exception text.
- #724 tablet detail stale-route fixed in PR #166; #718 settings load failure listener propagation in PR #168.

## Platform, build and upstream holds

- `ROADMAP.md` at repository root is authoritative; `UPSTREAM_TRIAGE.md` contains detailed upstream issue mapping. `AGENTS.md` and `docs/ARCHITECTURE.md` apply.
- Generated Pi-hole FTL v6.7 client pinned and reproducible. Remaining handwritten v6 paths are intentionally bounded to `/api/info/ftl` compatibility, detailed `/api/network/gateway` schema gap and gravity streaming contract. Keep guards and test coverage.
- `sqlite3 >=3.5.2 <3.6.0` due to current Flutter 3.44.1 / `meta` resolver constraints; don't force overrides.
- Upstream audit cursor `b3c940460ba7f25e7ef2fd0328fc91b2ed0a2abe` (merged #766); upstream #767 generated code requires pinned-generator parity; #768 privacy/copyright change requires independent fork policy review.
- Device checks remain unresolved: #442 Android 16 PopupMenu; #636 Android 17 self-signed TLS (capture App Log); #501 widget display density; #293 secure-storage migration; #686 Android IME; #741 Android 17 Impeller/Vulkan. Optional failed API integration smoke with `mock_api_server --fail all` / `--fail auth/sessions` also unperformed.
- **Fork identity publication is on hold by user decision** pending potential upstream-maintainer collaboration. Do not resume branding/Android ID/F-Droid submission unless approved. Optional identity tools are archived under `tools/archive/fork-identity/` in PR #181 (`e88b27aa`); the F-Droid-compatible source-build path, free QR scanner, and unsigned APK verification remain active.

## Next autonomous work unit

1. Verify live `main` and any competing PRs before changing code. The immediately completed bounded unit was #185, so do not recreate its three Settings changes.
2. Audit remaining #720 UX outside these six Settings screens; identify at most one concrete, reproducible, testable scope (e.g. Logs/Groups/Clients), not a blanket loading-style rewrite. Preserve first-load skeleton, manual cached refresh, and nonblocking background paths as distinct cases. If no clear issue, move to the power-user roadmap.
3. Evaluate one independent power-user feature in order of validated user value and manageable scope: multi-Pi-hole dashboard, cross-server actions, saved Log Explorer filters, or automated OpenAPI-spec drift report. Keep implementation small, dedicated PR and observable regressions.
4. Full exact-head Dart/Flutter analyzer, unsigned Android source APK + signature verification, CodeQL, Sonar, Codecov and statics required for application changes. Docs-only PRs use lighter repository-controlled workflow.

## Autonomous integration protocol

Work on a short-lived branch from live `main`, use squash PR merge after passing exact-HEAD CI. Inspect GitHub source/diffs and CI selectively; do not poll tightly or download huge logs. Checkpoint meaningful units here, and prefer fresh conversations when GitHub history grows. GitHub Issues are disabled in this fork (HTTP 410).
