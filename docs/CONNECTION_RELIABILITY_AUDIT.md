# V6 connection reliability: bounded technical audit

**Scope:** Current Dart/Flutter Pi-hole v6 connection/session layer. This is an investigation and implementation plan, not a verified production fix. No new dependencies or runtime changes.

## Current behavior already worth preserving

- `V6SessionCache` is shared per server through `V6SessionCacheStore`. Concurrent secure-storage loads share `_pendingLoad`; renewal requests share `_pendingRenewal` with a short post-success cooldown. The store is keyed by server address.
- SID credentials are backed by `SessionCredentialService` secure storage, not a process-global plaintext cache. Widget invalidation and SID updates are already wired.
- A server requiring TOTP sets an interactive reauthentication gate, avoiding repeated password-only background attempts and preserving explicit user interaction.
- `PiholeV6Service` uses a generated OpenAPI/Dio client with separate authenticated operations and an isolated unauthenticated auth probe; certificate policy and reverse-proxy subroutes must remain intact.
- `ApiException` already carries `statusCode`, API `errorCode`, `hint` and `message`. Existing repository tests cover ordinary 401 regeneration and retry. Avoid reimplementing these features.

## P1: Replay of ambiguous state-changing requests

**Observed code:** `lib/data/repositories/utils/call_with_retry.dart` defaults `runWithResultRetry` to `maxRetries: 1`. It repeats after a `Failure` or thrown error unless the error is an `AlreadyExistsException` or `GroupInUseException`. Its optional `onRetry` callback does not decide whether the action should be retried: after `onRetry` returns, the next attempt runs. Several v6 repositories wrap POST/PUT/PATCH/DELETE operations with this helper and `onRetry: (_, e) => renewSidIfExpired(e)`.

**Failure scenario:** A server commits a change but its response is lost or times out, or it returns an unrelated error. Blind replay can repeat that mutation. The code demonstrates this *possibility*; no live incident or data loss has been claimed.

**P1 implementation and validation:**

1. Add deterministic helper-level tests distinguishing `ApiException(statusCode: 401)`, `429`, `500`, missing-status timeouts/connection failures, and success. Check action execution counts; use a delayed/indeterminate response for at least one non-idempotent write.
2. Add repository-level cases for representative v6 add and delete operations, including `getSid()`/renewal involvement. Preserve a single legitimate 401 renewal/replay after session refresh, but do not replay ambiguous writes after unknown outcomes.
3. Design an explicit retry decision or an opt-in `retryWhen` predicate at the call site. Review existing uses of `runWithResultRetry` before altering defaults. Keep the scope to v6 mutating operations initially; leave read retries separately classified rather than globally changing both.
4. Verify concurrent 401s still share one renewal, and that TOTP-required/invalid/reused/rate-limited responses never trigger background auth loops. Do not retry session-creating `POST /api/auth` after ambiguous failure.
5. Ensure exceptions remain typed/redacted and downstream UI preserves failure and manual retry behavior. Do not silently interpret a 5xx as success or compensate a possibly committed write without a verified server response.

**Evidence:** `lib/data/repositories/api/v6/domain_repository.dart`, `group_repository.dart`, `local_dns_repository.dart`, `auth_repository.dart`, and `test/data/repositories/api/v6/*_generated_retry_test.dart`. In particular `auth_repository.dart` already uses `maxRetries: 0` for session creation due to the duplicate-session risk; preserve this exception.

## P2: Precise connection failures and timeout semantics

**Observed code:** `PiholeV6Service.fromConnection` configures separate Dio connect (5 s) and receive (3 s) timeouts. `safeDioCall` converts `DioException` through `ApiException.fromDioException`, preserving an actual HTTP response code when present; `SocketException` and `TimeoutException` also have fallback mappings. Native `DioExceptionType` timeout/cancel/connection distinctions are not retained as a stable, separate domain-level category.

**Possible improvement:** Add deterministic mapping tests for connection timeout, send timeout, receive timeout, DNS/socket failure, TLS handshake failure, cancellation, JSON error responses and empty/non-JSON bodies. Expose a *transport classification* only if Connection Doctor and UI can consume it without leaking addresses, SIDs or credentials, and without inventing an HTTP status for a request that never received one.

**Avoid premature changes:** Cached session expiry is currently handled reactively through 401 and secure SID renewal. Proactive validity tracking or probes can increase network/auth attempts, especially across multiple servers and TOTP setups. First measure real failures and request cost; do not introduce periodic auth probes as part of error classification.

## P2 implementation and evidence

- Integrated via PR #235, squash `b22a1bd42180e0697301ed61af9d6d1a79a7c80f`, exact final tested feature HEAD `9ff879e6442e2576895dc8120ae7920dc3bf86c7`.
- `ApiException` now exposes an optional `ApiTransportFailure` category. Known Dio connect/send/receive/**transform** timeouts, general timeout, connection, TLS and cancellation failures use fixed credential-free messages without inventing HTTP status. Normal and streaming wrappers also avoid fabricated 503/504 for raw `SocketException` or `TimeoutException`, and classify direct TLS errors. Actual Pi-hole HTTP error statuses and nested API error key/message/hint remain unchanged.
- Deterministic mapper and wrapper regressions include timeout stage distinction, TLS handshake, cancellation, wrapped Socket/Timeout errors, direct raw exceptions and secret exclusion. Initial exact-head CI detected Dio `transformTimeout` missing from the exhaustive switch; the final HEAD fixed and tested it. Full Flutter/analyzer, Sonar, Codecov, CodeQL/static, docs build and unsigned Android source APK including explicit `Verify unsigned release artifact` passed (15 successful/intentionally skipped checks).
- This closes the **typed transport categorization** slice, not physical network troubleshooting. Android 16/17, self-signed HTTPS, real Pi-hole v5/v6 and TLS pinning behavior still need device smoke. Unknown/unstructured exception sanitization and any UI/Connection Doctor display changes remain separate, evidence-driven decisions.

## Acceptance gates

- P1 was integrated in PR #233, squash `513ba4f76f895ab3cd4740cfba8d4c2188166ab9`, exact tested HEAD `004a4d265a750df7a9b1bd97cfb130ce50a76f6d`: all 16 applicable checks passed or were intentionally skipped including Flutter/analyzer, Sonar, Codecov, CodeQL/static, docs and verified unsigned Android source APK. The P2 typed transport failure slice is also integrated in PR #235 with full exact-head CI; physical-device/TLS smoke remains pending.
- Implementation requires an isolated branch, deterministic failing-before/fixed-after tests, no security-policy regressions, and exact HEAD Flutter/analyzer + applicable security/quality CI and unsigned Android source APK verification.
- Real Pi-hole v5/v6, Android 16/17, self-signed certificate behavior and proxy-device validation remain separate manual gates.
