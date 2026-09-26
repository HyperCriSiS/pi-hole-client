# AI Session State

Updated: 2026-09-26
Authority: `main`

This is the compact operational handoff for autonomous Pi-hole Client work. `ROADMAP.md` remains the strategic source of truth. Chat/tool history is not project state.

## Baseline
- Repository: `HyperCriSiS/pi-hole-client`
- Default branch: `main`
- Integrated product baseline at this checkpoint: `773cba3aa973aa519259a56d9ca3c4b1007ec6b9`
- Open pull requests after the block: none.

## Completed upstream delta sequence
- #734 Local DNS multi-hostname + duplicate guard was selectively integrated in fork PR #113.
- #751 v5 fallback back-navigation was selectively integrated in fork PR #114.
- #749 Android widget/server synchronization was selectively integrated in fork PR #115.
- Upstream #735 is fully ported through fork PRs #116-#120:
  - #116: shared duplicate detection and generated-v6 Domain save mapping.
  - #117: generated-v6 Client + Adlist duplicate mapping.
  - #118: generated-v6 Group duplicate mapping, old-database Group-in-use handling, non-retry semantics, and real generated `ApiException`/`error.hint` support.
  - #119: legacy-v5 Domain responses that say `already on the list` despite `success: true`.
  - #120: final UI feedback slice.

## PR #120
- PR: `fix(ui): explain duplicate save failures`
- Squash merge: `773cba3aa973aa519259a56d9ca3c4b1007ec6b9`
- Added shared duplicate-aware save feedback and applied it to Domain, Client, Adlist, Group and query-log add/update flows.
- Preserved the fork's existing Local DNS duplicate UX from #113.
- Added explanatory `GroupInUseException` feedback in the fork's Group details flow.
- Added focused snackbar/localization tests.
- Full Dart tests, unsigned Android source build + unsigned-artifact verification, CodeQL, Sonar, Codecov and static analyses passed.
- The separate GitHub-managed `github-advanced-security` AI-agent job again failed independently of repository-controlled gates.

## Upstream #735 state
Complete. No known functional delta from #735 remains for this fork.

## Upstream #737 refresh
- Upstream #727 is closed and has been superseded by open dependency-group PR #737.
- Most compatible #737 versions are already present in this fork.
- Fork validation PR #121 tested the only two plausible remaining small deltas with the repository-pinned Flutter 3.44.1 resolver and was closed without merge.
- `mockito 5.8.1` is blocked:
  - `freezed 3.2.5` requires analyzer <11.
  - `mockito >=5.8.0` requires analyzer >=13.3.
  - The solver rejects the combination, so Mockito remains at 5.6.4 until the Freezed/toolchain migration.
- `sqlite3 3.6.0` is also blocked:
  - sqlite3 3.6.0 requires `hooks ^2.2.0`.
  - hooks pulls `record_use ^1.0.0`, which requires `meta ^1.19.0`.
  - Flutter 3.44.1 pins `meta 1.18.0`.
  - The solver explicitly recommends retaining sqlite3 3.5.2.
- The existing F-Droid `sqlite3 source: system` hook itself remains compatible with sqlite3 3.6.0; the blocker is dependency resolution, not the hook syntax.
- No #737 dependency change was merged into `main`.

## Active roadmap state
- #639 generated Pi-hole v6 migration remains intentionally bounded. Production handwritten holds remain:
  - `/api/info/ftl`: generated schema still does not model the legacy/current counter union.
  - detailed `/api/network/gateway`: generated models omit interface/route detail already exposed by the app.
  - gravity update: generated endpoint does not preserve the current streaming progress contract.
- Device-dependent items still require affected-device evidence before production changes:
  - #442 Android 16 PopupMenu confirmation
  - #636 Android 17 self-signed HTTPS reproduction/App Log
  - #501 widget layout/density validation
  - #293 secure-storage/auth migration validation
- #134 F-Droid packaging remains blocked on the independent-fork product identity decision before applying the existing migration helper and drafting downstream metadata.
- #737 is triaged and currently blocked by pinned Flutter/Freezed dependency constraints; do not force analyzer/meta overrides.
- #646 remains a large draft TLS/cache refactor and should only be reconsidered as a deliberate rework, not cherry-picked.

## Next autonomous work block
There is no currently documented deterministic production change that should be implemented without new evidence, an upstream change, or a product decision.

Next autonomous action:
1. On a later maintenance pass, refresh only upstream PRs/issues changed since this checkpoint.
2. Reconsider #737 only after Flutter/Freezed pins move enough for the solver blockers above to disappear.
3. For device-gated #442/#636/#501/#293, wait for affected-device evidence before production changes.
4. For #134, wait for the independent-fork product identity decision.
5. Do not change production behavior merely to create work.

## Resume protocol
1. Read this file, `ROADMAP.md`, and `UPSTREAM_TRIAGE.md` from `main`.
2. Resolve `main` HEAD live and verify it is at or beyond `c68b6910`.
3. Confirm there are no open fork PRs.
4. Refresh upstream selectively only when there are newer changes than this checkpoint.
5. Keep any future implementation in one bounded short-lived PR and validate with repository-controlled gates.
