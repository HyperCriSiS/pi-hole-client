# AI Session State

Updated: 2026-09-26
Authority: `main`

This is the compact operational handoff for autonomous Pi-hole Client work. `ROADMAP.md` remains the strategic source of truth. Chat/tool history is not project state.

## Baseline
- Repository: `HyperCriSiS/pi-hole-client`
- Default branch: `main`
- Integrated product baseline at this checkpoint: `5ec045873c34d0c21d048a6c3866bf6a4a591fe8`
- Open pull requests after the block: none.

## Completed in the latest work blocks
- PR #113 `feat(local-dns): support multiple hostnames and duplicate guard`
  - selectively ports upstream `tsutsu3/pi-hole-client#734`
  - supports normalized whitespace-separated Local DNS hostnames, preflight duplicate protection, first-match edit/delete behavior, localized duplicate feedback and focused tests
  - preserves the fork's existing CNAME support and generic `AlreadyExistsException` foundation.
- PR #114 `fix(routing): restore back navigation on v5 fallbacks`
  - selectively ports upstream #751
  - restores explicit back navigation on v6-only fallback screens while retaining the legacy/default route behavior
  - merged as `53a2dc1cdd46b1cafeed31bc33ef8d53b275c517`.
- PR #115 `fix(widget): keep widgets synced with server changes`
  - selectively ports upstream #749
  - remaps Android widget bindings when a server address changes, resets widgets after server deletion, and propagates server replacement through the widget channel
  - Dart tests, unsigned Android source build, CodeQL, Sonar and Codecov were green
  - squash-merged as `e6d70d2323199be599bd8bbc147a0ea9da0c973d`.
- PR #116 `fix(domain): map duplicate save responses`
  - first bounded semantic port from upstream #735 onto the fork's generated-v6 architecture
  - maps current FTL HTTP-4xx duplicate failures and older successful responses carrying duplicate details in `processed.errors` to the existing `AlreadyExistsException`
  - widens shared processed-error handling to tolerate nullable generated error strings
  - teaches the shared duplicate detector the legacy v5 `already on the list` phrase for the later v5 repository slice
  - full Dart tests, unsigned Android source build + unsigned-artifact verification, audit, CodeQL, Sonar, Codecov and static analyses passed
  - squash-merged as `f43dbf5212d9fd77f889a267b31fb388c7b749aa`.
- PR #117 `fix(v6): map client and adlist duplicates`
  - second bounded semantic port from upstream #735
  - maps generated-v6 Client and Adlist add/update duplicates for both current HTTP-4xx responses and older successful `processed.errors` responses
  - reuses the shared duplicate helper from #116 and verifies duplicate requests are sent only once
  - full Dart tests, unsigned Android source build + unsigned-artifact verification, audit, CodeQL, Sonar, Codecov and static analyses passed
  - squash-merged as `7abaaa35b7fc5c63db25fc267e15356332ba859e`.
- PR #118 `fix(v6): map generated group mutation errors`
  - third bounded semantic port from upstream #735
  - adds generated-v6 Group add/update duplicate mapping and old-database Group delete `FOREIGN KEY constraint failed` mapping to `GroupInUseException`
  - stops retrying both `AlreadyExistsException` and `GroupInUseException`
  - fixes a generated-client transport mismatch found during the port: `safeDioCall` returns `ApiException`, while the prior shared duplicate helper only recognized `HttpStatusCodeException`
  - preserves Pi-hole's structured `error.hint` in `ApiException` and inspects message + hint, so Domain/Client/Adlist/Local-DNS duplicate mappings from earlier slices now also work against real generated 4xx responses
  - focused tests build errors through `ApiException.fromDioException` and verify duplicate/group-in-use requests are sent once
  - full Dart tests, unsigned Android source build + unsigned-artifact verification, audit, CodeQL, Sonar, Codecov and static analyses passed
  - the separate GitHub-managed `github-advanced-security` AI-agent job again failed independently of repository-controlled gates
  - squash-merged as `5ec045873c34d0c21d048a6c3866bf6a4a591fe8`.

## Active roadmap state
- #639 generated Pi-hole v6 migration remains intentionally bounded. Production handwritten holds remain:
  - `/api/info/ftl` because the generated FTL schema still does not model the legacy/current counter union.
  - detailed `/api/network/gateway` because generated models omit app-exposed interface/route detail.
  - gravity update because the generated endpoint does not preserve the current streaming progress contract.
- Device-dependent items still require affected-device evidence before production changes: #636, #501, #293 and final #442 confirmation.
- #134 F-Droid packaging remains blocked on the independent fork product identity choice before applying the existing migration helper and drafting downstream metadata.

## Upstream #735 delta state
Already covered:
- generic `AlreadyExistsException` foundation from #109
- generated v6 Local DNS/CNAME duplicate mapping from #112
- Local DNS duplicate preflight + localized feedback from #113
- shared duplicate detector supports current 4xx, older UNIQUE-constraint processed errors and legacy v5 duplicate wording
- generated v6 Domain add/update duplicate mapping from #116
- generated v6 Client add/update duplicate mapping from #117
- generated v6 Adlist add/update duplicate mapping from #117
- generated v6 Group add/update duplicate mapping from #118
- old-database Group-in-use delete mapping + non-retry semantics from #118
- real generated `ApiException` + Pi-hole `error.hint` support for the shared v6 mutation-error path from #118

Still missing from #735:
1. Legacy Pi-hole v5 duplicate-domain result mapping.
2. Remaining UI duplicate/group-in-use feedback for domain/group/client/adlist/query-log flows, preferably through a shared save-failure helper where it fits the fork without regressing existing Local DNS behavior.

## Next work block
Port only the legacy Pi-hole v5 duplicate-domain result mapping:
- inspect the current v5 Domain repository/client result contract and upstream #735 delta
- reuse `isDuplicateError` / `AlreadyExistsException` rather than duplicating phrase matching
- preserve all existing v5 add/update semantics and do not touch v6 code
- add focused v5 repository tests for duplicate vs normal success/error results
- do not touch UI behavior in this slice

## Resume protocol
1. Read this file and `ROADMAP.md` from `main`.
2. Resolve `main` HEAD live and verify it is at or beyond `5ec04587`.
3. Load only the current v5 Domain repository/client model needed for add/update and its focused tests.
4. Compare the exact upstream #735 v5 change before editing; do not import unrelated UI changes.
5. Implement on a short-lived branch and validate through a focused PR.
6. Merge only after repository-controlled gates pass.
7. Update this checkpoint before starting the remaining UI slice.
