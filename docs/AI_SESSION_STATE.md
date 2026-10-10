# AI Session State

Updated: 2026-10-11 (#720 Home metric placeholders validated)

## Integrated baseline

- Canonical branch: `main` in `HyperCriSiS/pi-hole-client`.
- Latest application merge: **PR #195**, squash `17890308a1a5de8ec65c6ce59ba9c2a49f3e164e`, exact validated feature HEAD `416fe20c8da18275ad3d683dcec94bfffee41211`. Prior Logs PR #193 (`7510a1ce262b3041e5058c716b98ac7ef3c3fa57`) and Groups/Clients PR #190 (`ed5682636ba950defe05641dd3704ebed3718c8c`).
- Latest dependency merge: **PR #191**, squash `3fedf7c66015133e1a77818ca63a7f675b74d7d0`: website `@typescript-eslint/parser` 8.71.0 → 8.71.1; website deployment test passed.
- #720 Groups/Clients **PR #190**: successful-empty cache is distinguished from initial state; prior groups and clients are kept visible during refresh and failed revalidation; nonblocking progress and localized stale-data warning; overlapping refresh guarded; repository seams, ViewModel regressions and widget regressions added. All applicable 14 check runs passed or were intentionally skipped at tested HEAD: Dart test/analyzer, Sonar, Codecov, CodeQL, static analyses, unsigned source APK build and successful `Verify unsigned release artifact` in job 114315913460 (workflow 38087128774). No device smoke performed.
- #720 Query Logs **PR #193**: successful empty log result remains a valid cache; revalidation preserves the last successful logs (including empty lists) while pending and after failed pagination, avoids publishing partial failed replacements, shows a localized nonblocking warning, clears it on retry/server switch and preserves first-load error behavior. Added controllable pagination fake, three ViewModel regressions and screen warning test. Exact-HEAD Dart/analyzer in job 114321276715, Sonar, Codecov, CodeQL, four static analysis jobs, unsigned Android source APK and successful `Verify unsigned release artifact` in job 114321277054 (workflow 38088966740) all passed. No live device check.
- #720 HomeTiles **PR #195**: numeric example values are only used behind the first-load skeleton; when realtime status has not loaded but the overall loading status becomes `loaded` (e.g. overtime request finishes separately), display a neutral unavailable dash instead of fake statistics; retain real cached metrics without shimmer during revalidation. Four widget regressions validate unavailable, initial skeleton, cached refresh and first-load error. First CI run found only four incorrect exact-`Skeletonizer`-type test finders, fixed using subtype-aware predicate before final CI. Final exact HEAD full Flutter/analyzer job `114330758783`, Sonar, Codecov, CodeQL, four static analyses and unsigned source APK plus successful `Verify unsigned release artifact` job `114330758869` all passed. No device validation.
- #720 earlier: Server Info PR #176; DHCP PR #177; Network devices PR #178; Sessions, Interfaces, Local DNS PR #185 (`ad1a1941`); Domains successful-empty SWR PR #188 (`4d3c3bba`); Groups/Clients PR #190 (`ed568263`). Six Settings screens, Domains, Groups/Clients, Logs and Home KPI tiles now covered; #720 **not globally complete**.
- Security #766 secure-storage read failure fail-closed fix PR #183 (`c1406910`); #748 authentication/TOTP hardening previously completed. Never allow background load to open interactive TOTP prompts; explicit user-triggered refresh may use `refreshWithTotpRecovery`. Never expose credentials or raw exception text.

## Technical and release constraints

- `ROADMAP.md` authoritative; also follow `AGENTS.md`, `docs/ARCHITECTURE.md`, `UPSTREAM_TRIAGE.md`.
- Generated Pi-hole FTL v6.7 client pinned; remaining narrow handwritten compatibility paths intentionally guarded. `sqlite3 >=3.5.2 <3.6.0` due to Flutter 3.44.1 resolver constraints; no overrides.
- Fork identity / Android ID / F-Droid publication **on hold by user decision** pending upstream collaboration. Optional identity tools archived in PR #181. Source APK build remains unsigned and validated.
- Device checks still pending: #442 Android 16 PopupMenu, #636 Android 17 self-signed TLS, #501 density, #293 secure-storage migration, #686 IME, #741 Android 17 Impeller/Vulkan. Optional failed API smoke pending. No physical-device validation claimed.
- Upstream triage cursor `b3c940460ba7f25e7ef2fd0328fc91b2ed0a2abe`; #767 generated-code parity and #768 privacy/copyright review pending.

## Next autonomous work unit

1. Recheck live `main`, PRs and targeted CI before modifying. Do not repeat merged #190–#195 or this checkpoint.
2. Audit and regression-test one bounded **StatusViewModel** #720 failure-state race: `_fetchOverTimeData` sets `_statusLoading = LoadStatus.loaded` even if `_fetchStatusData` failed. Confirm desired independent loading/error semantics before editing; preserve manual refresh and avoid new interactive TOTP prompts. Separately assessed follow-up: Home chart sections currently render skeleton/error in place of cached `OverTime` data during refresh/failure. Scope that as a distinct feature PR only with regressions; do not blanket-rewrite chart loading.
3. If no concrete #720 issue, implement a small validated power-user roadmap slice: multi-Pi-hole dashboard, cross-server actions, saved Log Explorer filters or automated OpenAPI drift report, prioritized by feasibility.
4. For application PRs require exact-HEAD Dart/analyzer, source APK + unsigned verification, CodeQL, Sonar, Codecov, static checks. Squash merge only after passes. Docs-only change uses lighter workflow.

## Operational protocol

- Short-lived branches and focused PRs. Targeted GitHub/CI reads; avoid large logs/diffs and tight polling.
- After a meaningful unit update this file and squash merge its docs PR. Prefer fresh chat after long GitHub tool histories.
- GitHub Issues disabled in fork (HTTP 410); upstream numbers are references, not writable local issues.
