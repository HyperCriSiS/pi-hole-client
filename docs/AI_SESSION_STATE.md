# AI Session State

Updated: 2026-09-23
Authority: `main`

This is the compact operational handoff for autonomous Pi-hole Client work. `ROADMAP.md` remains the strategic source of truth. Chat/tool history is not project state.

## Baseline
- Repository: `HyperCriSiS/pi-hole-client`
- Default branch: `main`
- Integrated product baseline before this checkpoint: `6fdb8f3f0d6c3230be0869c79386ab9fbcd1549c`
- Last completed work block: duplicate/handled-command error foundation follow-ups integrated.
- Open pull requests after the block: none.

## Completed in the latest work block
- PR #111 `fix(sentry): keep handled command errors local`
  - merged as `9bfbdf2e2ea203574d353ccf8567e0703a8815ad`
  - handled DHCP/network/session/Local-DNS/CNAME command failures stay local instead of reaching the global exception handler.
- PR #112 `fix(local-dns): map generated duplicate errors`
  - merged as `6fdb8f3f0d6c3230be0869c79386ab9fbcd1549c`
  - generated Local DNS/CNAME duplicate responses map to `AlreadyExistsException` and are not retried.
- For both PRs, Dart tests, CodeQL, Sonar, Codecov and the unsigned Android source build were green.
- The separate GitHub-managed `github-advanced-security` AI-agent job failed during its Processing Request step on both PRs; repository-controlled validation gates were green.

## Active roadmap state
- #639 generated Pi-hole v6 migration remains intentionally bounded. Production handwritten holds remain:
  - `/api/info/ftl` because the generated FTL schema still does not model the legacy/current counter union.
  - detailed `/api/network/gateway` because generated models omit app-exposed interface/route detail.
  - gravity update because the generated endpoint does not preserve the current streaming progress contract.
- Device-dependent items still require affected-device evidence before production changes: #636, #501, #293 and final #442 confirmation.
- #134 F-Droid packaging remains blocked on the independent fork product identity choice before applying the existing migration helper and drafting downstream metadata.

## Next work block
Selective port of upstream PR #734 (`feat(local-dns): allow multiple hostnames and block duplicate records`) onto current fork `main`.

Scope:
1. Support normalized space-separated Local DNS hostnames.
2. Add preflight duplicate detection in the Local DNS ViewModel while preserving the fork's CNAME support.
3. Keep edit/delete semantics aligned with the server when identical records exist: change/remove only the first match.
4. Surface a dedicated localized Local DNS duplicate message for add/update.
5. Add focused validator, ViewModel and widget regression tests.
6. Do not fold the broader upstream #735 domain/group/client/adlist duplicate UX into this block; handle it separately after #734 is integrated.

## Resume protocol
1. Read this file and `ROADMAP.md` from `main`.
2. Resolve `main` HEAD live and verify referenced PRs/SHAs.
3. Load only the Local DNS/validator/localization files required for upstream #734.
4. Create a short-lived branch from current `main`, implement and validate #734, then integrate through a PR.
5. Update this checkpoint after that block before starting the broader upstream #735 work.
