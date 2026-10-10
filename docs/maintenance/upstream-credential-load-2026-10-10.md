# Upstream review: secure-storage credential load (#766)

Reviewed: 2026-10-10
Repository: `HyperCriSiS/pi-hole-client`
Upstream cursor: `b3c940460ba7f25e7ef2fd0328fc91b2ed0a2abe` (2026-10-09)
Source: https://github.com/tsutsu3/pi-hole-client/pull/766

## P1 finding: real credential-read errors can become empty edit placeholders

Upstream #766 fixes server editing after a stored password/token read fails. Its upstream implementation cannot be copied wholesale because this fork already has a deliberately distinct #748 save-attempt rollback and secure-storage diagnostic/redaction pipeline.

The fork still has a concrete gap:

- `SecureStorageService.getValue()` maps both a missing secure-storage key and a storage read exception to generic failures. Missing optional credentials are valid, but I/O/decryption errors are not.
- `LocalServerRepository.fetchCredentials()` currently turns both kinds of failure into an empty password/token through `getOrElse((_) => '')`.
- In `AddServerFullscreen._loadSecrets()`, a failed fetch completes the loading flag, enabling Save even though the credentials were never recovered.
- The existing `secretsLoadSucceeded` rollback safeguard avoids one specific destructive restore but does **not** prevent a save using empty placeholders.

**Status: resolved in the fork via PR #183**, squash `c14069103475160356d7e88be7643958c9da584e` (final tested HEAD `8fc0be0c`). Exact-HEAD full Dart tests, unsigned Android release source build + artefact verification, CodeQL, Sonar, Codecov and static checks passed. No physical Android keystore failure reproduced.

## Implementation result

The original failure analysis above is preserved for history; it describes the **pre-fix** state. The fork now distinguishes absent optional credentials from real secure-storage failures, propagates failed reads, disables Save during/after failed loads, and exposes a localized explicit retry that retains drafts until successful retrieval. Existing `_SaveAttempt` and `secretsLoadSucceeded` rollback, TOTP and shared diagnostic redaction remain unchanged. Added service, repository and widget regressions; full CI passed on final PR HEAD. See `docs/AI_SESSION_STATE.md` for the current handoff.

## Required bounded remediation (completed)

1. Preserve the fork's centralized secret-redacting App Log / diagnostic behavior, while distinguishing a key that is genuinely absent from a read/decryption failure without logging key contents, token, SID or password.
2. In `fetchCredentials()`, only absent values may map to empty credentials; propagate real read failures.
3. For *edit* mode, block Save while credentials are loading **or have failed**, display a localized error and offer explicit Reload. Never silently reset existing secret inputs on load failure.
4. Check the #748 `_SaveAttempt` rollback and same-address / changed-address cases independently. **Do not automatically drop `secretsLoadSucceeded`** just because upstream removed it.
5. Test missing vs. failed reads, successful retry, Save lockout, no data loss and rollback. Require full Dart tests, unsigned Android source APK + artifact check, CodeQL, Sonar, Codecov and static checks before merging.

Relevant fork paths: `lib/data/services/local/secure_storage_service.dart`, `lib/data/repositories/local/server_repository.dart`, `lib/ui/servers/widgets/add_server_fullscreen.dart`, `lib/ui/servers/view_models/add_server_viewmodel.dart`.

## Other new upstream changes

- `0c9e9d85b501f946f0850b5211c7da6a1447d310` / upstream #768: documentation-only privacy-policy URL and copyright update. Review separately against this fork's independent policy and attribution; it is not an automatic functional merge.
- Upstream #767 remains a codegen-regeneration PR at this review. Do not import generated code without pinned generator parity.
- Earlier cursor `445424380076d09293ca1a2ce638d6f144e27233` was audited through #765 in the previous handoff.

GitHub Issues are disabled in this fork (HTTP 410 on attempted issue creation). Keep this P1 gap in roadmap/session tracking until implemented and validated.
