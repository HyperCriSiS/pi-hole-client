# AI Session State

Updated: 2026-09-25
Authority: `main`

This is the compact operational handoff for autonomous Pi-hole Client work. `ROADMAP.md` remains the strategic source of truth. Chat/tool history is not project state.

## Baseline
- Repository: `HyperCriSiS/pi-hole-client`
- Default branch: `main`
- Integrated product baseline at this checkpoint: `f43dbf5212d9fd77f889a267b31fb388c7b749aa`
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
  - adds focused generated-service tests and verifies duplicate failures are not retried
  - full Dart tests, unsigned Android source build + unsigned-artifact verification, audit, CodeQL, Sonar, Codecov and static analyses passed
  - the separate GitHub-managed `github-advanced-security` AI-agent job again failed independently of repository-controlled gates
  - squash-merged as `f43dbf5212d9fd77f889a267b31fb388c7b749aa`.

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

Still missing from #735:
1. Generated v6 Client duplicate mapping.
2. Generated v6 Adlist duplicate mapping.
3. Generated v6 Group duplicate mapping plus old-database group-in-use delete handling and no-retry semantics.
4. Legacy Pi-hole v5 duplicate-domain result mapping.
5. Remaining UI duplicate/group-in-use feedback for domain/group/client/adlist/query-log flows, preferably through a shared save-failure helper where it fits the fork without regressing existing Local DNS behavior.

## Next work block
Port generated v6 Client + Adlist duplicate handling as one small, mechanically identical slice:
- use the existing shared duplicate helper from #116
- map both HTTP-4xx duplicates and older `processed.errors` duplicates
- add focused generated-service tests
- keep Group handling separate because it introduces `GroupInUseException` and retry-policy changes
- do not touch UI or v5 behavior in this slice

## Resume protocol
1. Read this file and `ROADMAP.md` from `main`.
2. Resolve `main` HEAD live and verify it is at or beyond `f43dbf5`.
3. Load only current generated v6 Client/Adlist repository files and their focused tests.
4. Implement the two duplicate mappings on a short-lived branch using the fork's `PiholeV6Service`, not the upstream handwritten-client code.
5. Validate through a focused PR; merge only after repository-controlled gates pass.
6. Update this checkpoint before starting Group/v5/UI follow-ups.
