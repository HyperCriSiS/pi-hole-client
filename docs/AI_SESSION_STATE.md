# AI Session State

Updated: 2026-10-10

## Baseline and active work

- Repository: `HyperCriSiS/pi-hole-client`; `main` is the canonical integration branch. Work in short-lived topic branches with PRs and validate the exact final PR HEAD.
- Last fully validated **merged** feature at checkpoint: #720 Server Info revalidation, PR #176, squash commit `6728a230156ff1f1e30174f68c0599cd6de892da`. Full Dart, unsigned Android APK/signature verification, CodeQL, Sonar, Codecov and static analysis succeeded on PR HEAD `2d4f1eeb`.
- Active #720 follow-ups: PR #177 DHCP lease revalidation (`feat/720-dhcp-refresh`, HEAD `9fa28613`) and PR #178 Network-device revalidation (`feat/720-network-refresh`, HEAD `0b8a731a`). Both preserve successful content, show progress/stale errors and have widget regressions. **Do not mark as merged until full CI passes on their exact commits.** They are intentionally independent, and both derive from `main` after #176.
- New upstream audit: docs-only PR #179 records the **unfixed P1 credential-read/edit risk** from upstream #766 at `docs/maintenance/upstream-credential-load-2026-10-10.md`. GitHub Issues are disabled in this fork (HTTP 410); track in repository docs/roadmap.
- CI policy: no merge with failing/unverified full Dart tests, Android unsigned source APK and `Verify unsigned release artifact`, CodeQL, Sonar, Codecov or applicable static checks. Tests on an earlier HEAD do not validate new commits.

## Completed architecture foundations

- #748 authentication/session recovery complete in fork: #135 SaveAttempt lifecycle and rollback, #138 existing-session probe, #144 shared interactive login and blocking verification, #146 interactive vs background recovery/declined TOTP policy, #148 centrally redacted connection diagnostics. The upstream issue may still be open; do not duplicate the fork work.
- Explicit user-triggered refresh recovery uses shared `refreshWithTotpRecovery` (PR #129). No automatic/background prompt loops; do not change TOTP session or credential restoration policy casually.
- Connection Doctor complete in bounded slices: #152 read-only server capabilities/TLS/session summary, #170 existing FTL-batch elapsed time/outcome, #172 conditional Gravity timeout/nginx-buffering guidance, #174 manually started v6 per-endpoint read-only diagnostics. No synthetic pings, credential leakage or second auth flow.
- Upstream #724 Group/Client detail after successful delete fixed via #166; #718 settings failed-load notification/retry on six ViewModels fixed via #168. Both passed full repository-controlled CI.
- Pinned v6.7 OpenAPI client migration and architecture guard constrain remaining handwritten transport to `/api/info/ftl`, detailed `/api/network/gateway` and gravity streaming, for documented schema/behavior holds.
- `sqlite3` is intentionally restricted to `>=3.5.2 <3.6.0` pending Flutter SDK support for `meta ^1.19.0`; preserve pinned Flutter/Dart and F-Droid/native packaging boundaries.

## New upstream gap (P1, open)

- Upstream `tsutsu3/pi-hole-client` #766 merged as `b3c940460ba7f25e7ef2fd0328fc91b2ed0a2abe` on 2026-10-09. Our fork's secure-storage read failures can still become empty credential placeholders in `fetchCredentials`, and edit Save can be enabled after failed load.
- **Next prioritized security fix:** distinguish genuinely missing keys vs read errors, propagate failed credential fetches, block Save on failed loading and permit explicit Reload, and preserve #748 rollback/redaction semantics. Cover data-loss regressions; upstream code must not be imported blindly because fork architecture differs. See the dedicated audit document.
- Upstream #768 privacy-policy/copyright change requires fork-specific attribution review; upstream #767 codegen regeneration is not a safe blanket import without pinned generator parity.
- Previous audited upstream baseline was `445424380076d09293ca1a2ce638d6f144e27233` (#765). New review cursor: `b3c940460ba7f25e7ef2fd0328fc91b2ed0a2abe`.

## Roadmap / holds

1. Finish the full exact-HEAD CI and merge #177/#178 only if all gates pass. Correct failures on their own branches and re-run CI after changes.
2. Implement upstream #766 credential-read/save lockout as a separate **P1** bounded security slice with regression tests, preserving established fork auth/rollback boundaries.
3. Continue #720 across remaining settings/screens: first-load skeletons vs manual cached revalidation vs background refresh must be differentiated, and #718 error/retry retained. Next candidates: Sessions, Local DNS, Interfaces, and broader list views.
4. Evaluate next power-user roadmap only after architecture work: multi-Pi-hole dashboard, cross-server actions, saved Log Explorer filters, automatic OpenAPI drift reporting.
5. Separate optional failed-API `mock_api_server --fail all` / `--fail auth/sessions` integration smoke, real-server reverse-proxy diagnostics and device-dependent tests. Never claim a missing reproduction is fixed.
6. Device/distribution holds: #442 Android 16 PopupMenu device retest, #636 Android 17 self-signed TLS with App Log, #501 widget density tablet, #293 secure-storage migration, #686 Android IME/bottom-sheet, #741 Android 17 Impeller/Vulkan; #134 final independent fork ID/name/icon and F-Droid submission decision.

## Resume protocol

1. Read this checkpoint, root `ROADMAP.md`, `UPSTREAM_TRIAGE.md`, `AGENTS.md` and relevant architecture document.
2. Confirm live `main` SHA, open PRs and exact-HEAD CI before any merge/new overlapping slice; keep tool outputs targeted and avoid tight CI polling.
3. For substantial completed work, update this checkpoint with merge SHA and remaining blockers. If tool history becomes large, use a fresh chat after a clean checkpoint.
