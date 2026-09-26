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
- Upstream #735 is now fully ported through fork PRs #116-#120:
  - #116: shared duplicate detection and generated-v6 Domain save mapping.
  - #117: generated-v6 Client + Adlist duplicate mapping.
  - #118: generated-v6 Group duplicate mapping, old-database Group-in-use handling, non-retry semantics, and real generated `ApiException`/`error.hint` support.
  - #119: legacy-v5 Domain responses that say `already on the list` despite `success: true`.
  - #120: final UI feedback slice.

## PR #120
- PR: `fix(ui): explain duplicate save failures`
- Squash merge: `773cba3aa973aa519259a56d9ca3c4b1007ec6b9`
- Added a shared `showSaveFailedSnackBar` helper:
  - `AlreadyExistsException` -> caution / already-added feedback.
  - other failures -> normal save-failed error.
- Applied duplicate-aware feedback to:
  - Domain add/update
  - Client add
  - Adlist add
  - Group add/update
  - query-log whitelist/blacklist add actions
- Preserved the fork's existing Local DNS duplicate UX from #113 rather than replacing it.
- Adapted upstream Group delete behavior to the fork's current `group_details_screen.dart` structure:
  - `GroupInUseException` now explains that clients/domains/adlists must release the group first.
  - generic delete failures keep the existing message.
- Added focused snackbar tests and five-locale Group-in-use message coverage.
- To avoid a ~200 KB whole-file ARB rewrite through the GitHub contents interface for one string, the new Group-in-use text is provided as a small `AppLocalizations` extension for en/de/es/ja/pl with English fallback. The getter name is `groupInUse`, so a future generated localization getter can transparently supersede the extension.
- Repository-controlled gates passed:
  - full Dart tests
  - unsigned Android source APK
  - unsigned-artifact verification
  - CodeQL
  - Sonar
  - Codecov
  - static analyses / package-identity audit
- The separate GitHub-managed `github-advanced-security` AI-agent job again failed independently of repository-controlled gates.

## Upstream #735 state
Complete. No known functional delta from #735 remains for this fork.

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
- #727 should not be imported wholesale; compatible patch/minor parts are already present and its remaining majors/previews conflict with the current pinned toolchain/platform choices.
- #646 remains a large draft TLS/cache refactor and should only be reconsidered as a deliberate rework, not cherry-picked.

## Next autonomous work block
There is no currently documented deterministic production change that should be implemented without new evidence or a product decision.

Next autonomous action:
1. Refresh the upstream open-PR delta list against current `main`.
2. Add genuinely new upstream candidates to `UPSTREAM_TRIAGE.md`.
3. For any new deterministic candidate, build a small already-present / missing / conflicting delta before implementation.
4. If no new candidate exists, stop rather than changing production behavior behind the device/product gates above.

## Resume protocol
1. Read this file, `ROADMAP.md`, and `UPSTREAM_TRIAGE.md` from `main`.
2. Resolve `main` HEAD live and verify it is at or beyond `773cba3a`.
3. Confirm there are no open fork PRs.
4. Refresh upstream open PRs selectively; do not re-audit closed/completed work unless upstream changed it.
5. Keep the next implementation, if any, in one bounded short-lived PR.
