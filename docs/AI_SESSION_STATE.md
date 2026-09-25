# AI Session State

Updated: 2026-09-25
Authority: `main`

This is the compact operational handoff for autonomous Pi-hole Client work. `ROADMAP.md` remains the strategic source of truth. Chat/tool history is not project state.

## Baseline
- Repository: `HyperCriSiS/pi-hole-client`
- Default branch: `main`
- Integrated product baseline at this checkpoint: `e6d70d2323199be599bd8bbc147a0ea9da0c973d`
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
  - focused server ViewModel coverage passed before PR creation
  - Dart tests, unsigned Android source build, CodeQL, Sonar and Codecov were green
  - the separate GitHub-managed `github-advanced-security` AI-agent job failed during its Processing Request step, consistent with the known non-repository-controlled failure pattern
  - squash-merged as `e6d70d2323199be599bd8bbc147a0ea9da0c973d`.

## Active roadmap state
- #639 generated Pi-hole v6 migration remains intentionally bounded. Production handwritten holds remain:
  - `/api/info/ftl` because the generated FTL schema still does not model the legacy/current counter union.
  - detailed `/api/network/gateway` because generated models omit app-exposed interface/route detail.
  - gravity update because the generated endpoint does not preserve the current streaming progress contract.
- Device-dependent items still require affected-device evidence before production changes: #636, #501, #293 and final #442 confirmation.
- #134 F-Droid packaging remains blocked on the independent fork product identity choice before applying the existing migration helper and drafting downstream metadata.

## Next work block
Selective delta review/port of upstream PR #735 (`fix(ui): show "already added" when adding an item that already exists`).

Important fork overlap already present:
- generic `AlreadyExistsException` foundation from #109
- generated v6 Local DNS/CNAME duplicate mapping from #112
- Local DNS duplicate preflight + localized feedback from #113

Scope the next block to only missing #735 behavior, likely:
1. Domain/group/client/adlist duplicate response mapping that is not already covered.
2. Legacy Pi-hole v5 duplicate-domain handling if still absent.
3. Group-in-use delete mapping/message for older Pi-hole versions if still absent.
4. Shared duplicate/save-failure snackbar behavior only where it reduces remaining duplication without regressing fork-specific handling.
5. Focused repository/retry/UI tests for the missing deltas.

Do not re-import #735 wholesale; compare against current `main` first and exclude already-integrated Local DNS/foundation changes.

## Resume protocol
1. Read this file and `ROADMAP.md` from `main`.
2. Resolve `main` HEAD live and verify it is at or beyond `e6d70d2`.
3. Load upstream #735 changed-file list plus only matching fork files.
4. Produce a delta matrix: already present / missing / conflicts with fork behavior.
5. Implement one bounded missing-behavior slice on a short-lived branch and validate it through a PR.
6. Update this checkpoint after the slice before starting another large slice.
