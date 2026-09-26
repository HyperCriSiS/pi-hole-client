# AI Session State

Updated: 2026-09-26
Authority: `main`

This is the compact operational handoff for autonomous Pi-hole Client work. `ROADMAP.md` remains the strategic source of truth. Chat/tool history is not project state.

## Baseline
- Repository: `HyperCriSiS/pi-hole-client`
- Default branch: `main`
- Integrated product baseline at this checkpoint: `79912bf33bf39fcf70f87c8644cef982814c98ed`
- Open pull requests after the block: none.

## Recently completed upstream ports
- PR #113 selectively ported upstream #734: multiple Local DNS hostnames, duplicate guard, first-match edit/delete behavior and localized duplicate feedback while preserving fork CNAME support.
- PR #114 selectively ported upstream #751: restored explicit back navigation on v6-only fallback screens.
- PR #115 selectively ported upstream #749: kept Android widgets synchronized with server edits/deletions.
- PR #116 started the bounded semantic port of upstream #735:
  - shared duplicate detection for current HTTP-4xx, older `processed.errors`, and legacy v5 duplicate wording
  - generated-v6 Domain add/update duplicate mapping.
- PR #117 extended #735 handling to generated-v6 Client and Adlist add/update.
- PR #118 completed the generated-v6 repository error slice:
  - Group add/update duplicate mapping
  - old-database Group delete `FOREIGN KEY constraint failed` -> `GroupInUseException`
  - no retry for `AlreadyExistsException` and `GroupInUseException`
  - preserved Pi-hole `error.hint` in generated `ApiException`
  - taught the shared duplicate mapper to handle real generated `ApiException`, fixing the transport mismatch affecting prior v6 duplicate slices.
- PR #119 `fix(v5): map duplicate domain responses`
  - maps Pi-hole v5 responses that report `success: true` but say `already on the list` to `AlreadyExistsException`
  - keeps normal successful add behavior unchanged
  - maps explicit `success: false` responses to failures
  - focused tests verify duplicate responses are not retried
  - full Dart tests, unsigned Android source build + unsigned-artifact verification, CodeQL, Sonar, Codecov and static analyses passed
  - the separate GitHub-managed `github-advanced-security` AI-agent job again failed independently of repository-controlled gates
  - squash-merged as `79912bf33bf39fcf70f87c8644cef982814c98ed`.

## Active roadmap state
- #639 generated Pi-hole v6 migration remains intentionally bounded. Production handwritten holds remain:
  - `/api/info/ftl` because the generated FTL schema still does not model the legacy/current counter union.
  - detailed `/api/network/gateway` because generated models omit app-exposed interface/route detail.
  - gravity update because the generated endpoint does not preserve the current streaming progress contract.
- Device-dependent items still require affected-device evidence before production changes: #636, #501, #293 and final #442 confirmation.
- #134 F-Droid packaging remains blocked on the independent fork product identity choice before applying the existing migration helper and drafting downstream metadata.

## Upstream #735 delta state
Repository/data-layer behavior is now covered:
- generic `AlreadyExistsException`
- Local DNS duplicate mapping/preflight
- generated v6 Domain, Client, Adlist and Group duplicate mapping
- generated v6 Group-in-use delete mapping
- real generated `ApiException` + `error.hint` handling
- legacy v5 Domain duplicate-response mapping
- non-retry semantics for duplicate/group-in-use failures

Still missing from #735:
1. Remaining UI duplicate/group-in-use feedback for domain/group/client/adlist/query-log flows.
2. Prefer a shared save-failure snackbar/helper where that reduces duplication without regressing the fork's existing Local DNS-specific behavior.
3. Localization additions and focused widget/helper tests needed by that UI behavior.

## Next work block
Final upstream #735 UI delta review/port:
- load the upstream #735 UI/localization changed-file subset only
- compare each UI path against current fork behavior; do not blindly import the whole upstream UI diff
- preserve existing Local DNS duplicate UX from #113
- introduce/reuse shared save-failure feedback only where it fits current fork architecture
- map `AlreadyExistsException` to caution/"already added" feedback for Domain, Client, Adlist and relevant query-log add actions
- map `GroupInUseException` to an explanatory Group delete message
- add only required localization keys and focused UI/helper regression tests
- keep this as one final bounded #735 PR if the delta remains cohesive; split Group delete feedback if the UI delta becomes too broad

## Resume protocol
1. Read this file and `ROADMAP.md` from `main`.
2. Resolve `main` HEAD live and verify it is at or beyond `79912bf3`.
3. Load upstream #735 changed-file list, filtered to UI/localization/tests only.
4. Load only the matching current fork files and build an already-present / missing / conflicting delta matrix.
5. Implement the smallest cohesive UI slice on a short-lived branch.
6. Validate via PR and merge only after repository-controlled gates pass.
7. Update this checkpoint and mark the #735 port complete if no functional delta remains.
