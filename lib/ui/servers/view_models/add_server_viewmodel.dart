// NOTE: This view model intentionally depends on [ServersViewModel] and
// [StatusViewModel] (a cross-view-model dependency). The server-list mutations
// (addServer/editServer/replaceServer) are Commands whose notify/refresh side
// effects must be preserved, so the orchestration reuses them rather than the
// lower-level repositories. The certificate UI (pin dialog, ssl error snackbar)
// stays in the widget and is injected per request via [resolveCertificate].
import 'package:command_it/command_it.dart';
import 'package:flutter/foundation.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/repository_bundle.dart';
import 'package:pi_hole_client/domain/model/server/api_versions.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';
import 'package:pi_hole_client/domain/use_cases/server_connection/probe_existing_session.dart';
import 'package:pi_hole_client/ui/core/services/totp_login.dart';
import 'package:pi_hole_client/ui/core/types/resolve_totp.dart';
import 'package:pi_hole_client/ui/core/view_models/servers_viewmodel.dart';
import 'package:pi_hole_client/ui/core/view_models/status_viewmodel.dart';
import 'package:pi_hole_client/utils/logger.dart';
import 'package:pi_hole_client/utils/url.dart';

/// Resolves and validates the certificate for [server], returning the updated
/// server (possibly with a pinned fingerprint) or `null` when the user cancels
/// or the certificate is rejected. The dialog and ssl-error snackbar live in the
/// widget; the view model only decides what to do with the result.
typedef ResolveCertificate = Future<Server?> Function(Server server);

/// Request for [AddServerViewModel.createServer] (adding a new server).
class CreateServerRequest {
  const CreateServerRequest({
    required this.url,
    required this.alias,
    required this.apiVersion,
    required this.allowUntrustedCert,
    required this.ignoreCertificateErrors,
    required this.pinnedCertificateSha256,
    required this.password,
    required this.token,
    required this.defaultServer,
    required this.resolveCertificate,
    required this.resolveTotp,
  });

  final String url;
  final String alias;
  final String apiVersion;
  final bool allowUntrustedCert;
  final bool ignoreCertificateErrors;
  final String? pinnedCertificateSha256;
  final String password;
  final String token;
  final bool defaultServer;
  final ResolveCertificate resolveCertificate;
  final ResolveTotp resolveTotp;
}

/// Request for [AddServerViewModel.updateServer] (editing an existing server).
class UpdateServerRequest {
  const UpdateServerRequest({
    required this.url,
    required this.alias,
    required this.apiVersion,
    required this.allowUntrustedCert,
    required this.ignoreCertificateErrors,
    required this.pinnedCertificateSha256,
    required this.password,
    required this.token,
    required this.defaultServer,
    required this.oldServer,
    required this.initPassword,
    required this.initToken,
    required this.secretsLoadSucceeded,
    required this.resolveCertificate,
    required this.resolveTotp,
  });

  final String url;
  final String alias;
  final String apiVersion;
  final bool allowUntrustedCert;
  final bool ignoreCertificateErrors;
  final String? pinnedCertificateSha256;
  final String password;
  final String token;
  final bool defaultServer;
  final Server oldServer;

  /// The credentials originally loaded for [oldServer]. Used to restore the old
  /// secrets when a save attempt fails.
  final String initPassword;
  final String initToken;

  /// Whether the stored secrets were actually read. When false the restore is
  /// skipped so empty placeholders never overwrite a credential still in secure
  /// storage.
  final bool secretsLoadSucceeded;

  final ResolveCertificate resolveCertificate;
  final ResolveTotp resolveTotp;
}

// ==================================================================
// Outcome of [AddServerViewModel.createServer], mapped to UI by the widget.
// ==================================================================
sealed class CreateOutcome {
  const CreateOutcome();
}

final class CreateInitial extends CreateOutcome {
  const CreateInitial();
}

final class CreateSuccess extends CreateOutcome {
  const CreateSuccess(this.server);
  final Server server;
}

final class CreateCancelled extends CreateOutcome {
  const CreateCancelled();
}

final class CreateDuplicateUrl extends CreateOutcome {
  const CreateDuplicateUrl();
}

final class CreateUrlCheckFailed extends CreateOutcome {
  const CreateUrlCheckFailed();
}

final class CreateApiError extends CreateOutcome {
  const CreateApiError(this.error, this.version);
  final Exception error;
  final String version;
}

final class CreateDbError extends CreateOutcome {
  const CreateDbError();
}

// ==================================================================
// Outcome of [AddServerViewModel.updateServer], mapped to UI by the widget.
// ==================================================================
sealed class UpdateOutcome {
  const UpdateOutcome();
}

final class UpdateInitial extends UpdateOutcome {
  const UpdateInitial();
}

final class UpdateSuccess extends UpdateOutcome {
  const UpdateSuccess();
}

final class UpdateCancelled extends UpdateOutcome {
  const UpdateCancelled();
}

final class UpdateDuplicateUrl extends UpdateOutcome {
  const UpdateDuplicateUrl();
}

final class UpdateUrlCheckFailed extends UpdateOutcome {
  const UpdateUrlCheckFailed();
}

final class UpdateApiError extends UpdateOutcome {
  const UpdateApiError(this.error, this.version);
  final Exception error;
  final String version;
}

final class UpdateDbError extends UpdateOutcome {
  const UpdateDbError();
}

/// Result of a server-URL uniqueness check.
enum _UrlCheck { available, duplicate, failed }

/// Orchestrates adding ([createServer]) and editing ([updateServer]) a Pi-hole
/// server.
///
/// The view model owns the pure orchestration (URL uniqueness check, credential
/// storage, session creation/teardown, blocking-status probe, DB commit and
/// rollback). UI reactions (snackbars, navigation, the certificate dialog and
/// the connecting overlay) stay in the widget and are driven by the returned
/// sealed outcomes.
class AddServerViewModel extends ChangeNotifier {
  AddServerViewModel({
    required ServersViewModel serversViewModel,
    required StatusViewModel statusViewModel,
    required CreateRepositoryBundle createBundle,
  }) : _serversViewModel = serversViewModel,
       _statusViewModel = statusViewModel,
       _createBundle = createBundle {
    createServer = Command.createAsync<CreateServerRequest, CreateOutcome>(
      _createServer,
      initialValue: const CreateInitial(),
    );
    updateServer = Command.createAsync<UpdateServerRequest, UpdateOutcome>(
      _updateServer,
      initialValue: const UpdateInitial(),
    );
    createServer.addListener(notifyListeners);
    updateServer.addListener(notifyListeners);
  }

  final ServersViewModel _serversViewModel;
  final StatusViewModel _statusViewModel;
  final CreateRepositoryBundle _createBundle;

  late final Command<CreateServerRequest, CreateOutcome> createServer;
  late final Command<UpdateServerRequest, UpdateOutcome> updateServer;

  /// Maps [ServersViewModel.checkUrlExists]'s map result to a typed [_UrlCheck].
  Future<_UrlCheck> _checkUrl(String url) async {
    final result = await _serversViewModel.checkUrlExists(url);
    if (result['result'] == 'fail') return _UrlCheck.failed;
    return result['exists'] == true ? _UrlCheck.duplicate : _UrlCheck.available;
  }

  /// Persists password and token as one logical operation.
  ///
  /// Secure-storage operations return [Result], so a caller must not treat a
  /// failed write as a successful server save.
  Future<Exception?> _saveCredentials({
    required String address,
    required String password,
    required String token,
  }) async {
    final passwordResult = await _serversViewModel.savePassword(
      address,
      password,
    );
    if (passwordResult.isError()) {
      return passwordResult.exceptionOrNull() ??
          Exception('Failed to save password credential');
    }

    final tokenResult = await _serversViewModel.saveToken(address, token);
    if (tokenResult.isError()) {
      return tokenResult.exceptionOrNull() ??
          Exception('Failed to save token credential');
    }

    return null;
  }

  /// Adds a new server: checks the URL is not in use, resolves the certificate,
  /// saves the credentials, creates a v6 session if needed and checks the
  /// blocking status. Credentials saved during the attempt are removed on
  /// failure.
  ///
  /// A cancelled or blocked certificate aborts the add ([CreateCancelled])
  /// before anything is saved.
  ///
  /// Returns [CreateSuccess] with the server for the widget to save, or
  /// [CreateCancelled] / [CreateDuplicateUrl] / [CreateUrlCheckFailed] /
  /// [CreateApiError].
  Future<CreateOutcome> _createServer(CreateServerRequest req) async {
    switch (await _checkUrl(req.url)) {
      case _UrlCheck.duplicate:
        return const CreateDuplicateUrl();
      case _UrlCheck.failed:
        return const CreateUrlCheckFailed();
      case _UrlCheck.available:
        break;
    }

    var serverObj = Server(
      address: req.url,
      alias: req.alias,
      apiVersion: req.apiVersion,
      allowUntrustedCert: req.allowUntrustedCert,
      ignoreCertificateErrors: req.ignoreCertificateErrors,
      pinnedCertificateSha256: req.pinnedCertificateSha256,
    );

    // Resolve the certificate before saving anything, so a cancel/block aborts
    // cleanly with nothing to undo (same order as updateServer).
    final resolved = await req.resolveCertificate(serverObj);
    if (resolved == null) {
      return const CreateCancelled();
    }
    serverObj = resolved;

    final credentialError = await _saveCredentials(
      address: req.url,
      password: req.password,
      token: req.token,
    );
    if (credentialError != null) {
      await _serversViewModel.deletePassword(req.url);
      await _serversViewModel.deleteToken(req.url);
      return const CreateDbError();
    }

    final bundle = _createBundle(server: serverObj);
    if (serverObj.apiVersion == SupportedApiVersions.v6) {
      final login = await runTotpLogin(
        auth: bundle.auth,
        password: req.password,
        resolveTotp: req.resolveTotp,
      );
      if (login.cancelled) {
        await _serversViewModel.deletePassword(req.url);
        await _serversViewModel.deleteToken(req.url);
        return const CreateCancelled();
      }
      if (login.result.isError()) {
        await _serversViewModel.deletePassword(req.url);
        await _serversViewModel.deleteToken(req.url);
        return CreateApiError(login.result.exceptionOrNull()!, req.apiVersion);
      }
    }

    // Use skipRenewal: true because the session was just created above.
    // Retrying with clearAndRenewSid would create a duplicate session.
    // Transient errors (e.g. network timeout) are still retried.
    final result = await bundle.dns.fetchBlockingStatus(skipRenewal: true);
    if (result.isError()) {
      // Connection test failed: clean up everything saved for this attempt.
      await _cleanupCreateAttempt(bundle, req);
      return CreateApiError(result.exceptionOrNull()!, req.apiVersion);
    }

    // Persist the server row BEFORE reporting success.
    final server = serverObj.copyWith(defaultServer: req.defaultServer);
    try {
      await _serversViewModel.addServer.runAsync(server);
    } catch (e, s) {
      logger.e('Failed to save new server', error: e, stackTrace: s);
      await _cleanupCreateAttempt(bundle, req);
      return const CreateDbError();
    }
    return CreateSuccess(server);
  }

  /// Best-effort teardown of everything saved during a failed add-server
  /// attempt: the remote v6 session plus the stored password/token/sid.
  Future<void> _cleanupCreateAttempt(
    RepositoryBundle bundle,
    CreateServerRequest req,
  ) async {
    if (req.apiVersion == SupportedApiVersions.v6) {
      // Best-effort logout of the session created during login above.
      await bundle.auth.deleteCurrentSession();
    }
    await _serversViewModel.deletePassword(req.url);
    await _serversViewModel.deleteToken(req.url);
    await _serversViewModel.deleteSid(req.url);
  }

  /// Edits an existing server, keeping the old server's row, credentials and
  /// session unchanged until this attempt fully succeeds.
  ///
  /// Handles the address-changed (replace) vs same-address (in-place edit) paths,
  /// the v6 login branches (an address change always creates a session; a
  /// changed password is checked by creating one; an unchanged password keeps
  /// the current session and only logs in again on a 401), the DB save, and the
  /// rollback/old-session cleanup. Auto refresh is stopped while it runs and
  /// started again on every exit path.
  ///
  /// A cancelled or blocked certificate stops the save ([UpdateCancelled]); the
  /// message was already shown by [UpdateServerRequest.resolveCertificate].
  ///
  /// Returns [UpdateSuccess], [UpdateCancelled], [UpdateDuplicateUrl],
  /// [UpdateUrlCheckFailed], [UpdateApiError] or [UpdateDbError].
  Future<UpdateOutcome> _updateServer(UpdateServerRequest req) async {
    // Normalised comparison: a host-case-only or trailing-slash difference is
    // NOT an address change and must stay on the in-place editServer path.
    final isAddressChanged = !isSameEndpoint(req.oldServer.address, req.url);

    // When the address (primary key) changes, make sure the new URL is not
    // already used by another server before doing anything destructive.
    if (isAddressChanged) {
      switch (await _checkUrl(req.url)) {
        case _UrlCheck.duplicate:
          return const UpdateDuplicateUrl();
        case _UrlCheck.failed:
          return const UpdateUrlCheckFailed();
        case _UrlCheck.available:
          break;
      }
    }

    final attempt = _SaveAttempt(
      req: req,
      isAddressChanged: isAddressChanged,
      serversViewModel: _serversViewModel,
      statusViewModel: _statusViewModel,
      createBundle: _createBundle,
    );

    var serverObj = Server(
      address: attempt.targetAddress,
      alias: req.alias,
      apiVersion: req.apiVersion,
      allowUntrustedCert: req.allowUntrustedCert,
      ignoreCertificateErrors: req.ignoreCertificateErrors,
      // When the address changes the target is effectively a different host, so
      // any pinned certificate carried over from the old server is stale. Reset
      // it to null so the certificate check re-runs against the new host.
      pinnedCertificateSha256: isAddressChanged
          ? null
          : req.pinnedCertificateSha256,
    );

    if (_serversViewModel.selectedServer != null) {
      _statusViewModel.stopAutoRefresh();
    }

    // Validate certificate BEFORE connection test (same as connect()).
    final updatedServer = await req.resolveCertificate(serverObj);
    if (updatedServer == null) {
      attempt.restartAutoRefresh();
      return const UpdateCancelled();
    }
    serverObj = updatedServer;

    final credentialError = await _saveCredentials(
      address: attempt.targetAddress,
      password: req.password,
      token: req.token,
    );
    if (credentialError != null) {
      await attempt.rollbackCredentialWriteFailure();
      attempt.restartAutoRefresh();
      return const UpdateDbError();
    }

    final bundle = _createBundle(server: serverObj);
    final auth = await _authenticate(
      bundle: bundle,
      req: req,
      isAddressChanged: isAddressChanged,
    );
    if (auth.cancelled) {
      // User dismissed the TOTP prompt: undo this attempt's writes and keep the
      // old server (row, credentials, session) intact, same as a failed save.
      _serversViewModel.markTotpReauthDeclined(attempt.targetAddress);
      if (auth.needsRollback) {
        await attempt.rollback(bundle: bundle, sessionCreated: false);
      }
      await attempt.restoreSecrets();
      attempt.restartAutoRefresh();
      return const UpdateCancelled();
    }
    if (auth.error != null) {
      // Only the address-changed branch wrote credentials under a new address,
      // so it is the only one that needs a rollback before reporting the error.
      if (auth.needsRollback) {
        await attempt.rollback(bundle: bundle, sessionCreated: false);
      }
      await attempt.restoreSecrets();
      attempt.restartAutoRefresh();
      return UpdateApiError(auth.error!, req.apiVersion);
    }
    // skipRenewal: true only when a new session was just created above to avoid
    // creating a duplicate session on transient retry failures.
    final result = await bundle.dns.fetchBlockingStatus(
      skipRenewal: auth.sessionCreated,
    );

    if (result.isError()) {
      await attempt.rollback(
        bundle: bundle,
        sessionCreated: auth.sessionCreated,
      );
      attempt.restartAutoRefresh();
      return UpdateApiError(result.exceptionOrNull()!, req.apiVersion);
    }

    final server = serverObj.copyWith(defaultServer: req.defaultServer);

    final cmdError = await attempt.commit(server);
    if (cmdError != null) {
      // DB write failed: roll back this attempt's artifacts; the old server
      // (row, credentials, session) is left fully intact.
      await attempt.rollback(
        bundle: bundle,
        sessionCreated: auth.sessionCreated,
      );
      attempt.restartAutoRefresh();
      return const UpdateDbError();
    }

    await attempt.cleanupAfterCommit();
    _serversViewModel.clearTotpReauthDeclined(attempt.targetAddress);
    attempt.restartAutoRefresh();
    return const UpdateSuccess();
  }

  /// Ensures a valid v6 session exists before the connection test.
  ///
  /// - Non-v6: nothing to do.
  /// - Address changed: the new host has no session, so always create one.
  /// - Same address, password changed: validate the new password by creating a
  ///   session (so an unverified password can't silently replace the good one).
  /// - Same address, password unchanged: reuse the current session and only log
  ///   in again on a 401/SID-missing (avoids duplicate sessions on 503/504).
  ///
  /// On failure returns the error and `needsRollback` (true only for the
  /// address-changed branch, which already wrote new-address credentials).
  /// `cancelled` is true when the user dismissed the TOTP prompt.
  Future<
    ({
      bool sessionCreated,
      Exception? error,
      bool needsRollback,
      bool cancelled,
    })
  >
  _authenticate({
    required RepositoryBundle bundle,
    required UpdateServerRequest req,
    required bool isAddressChanged,
  }) async {
    // Maps a login attempt to the _authenticate result record. [needsRollback]
    // is carried through unchanged for the failure/cancel paths.
    Future<
      ({
        bool sessionCreated,
        Exception? error,
        bool needsRollback,
        bool cancelled,
      })
    >
    login({required bool needsRollback}) async {
      final result = await runTotpLogin(
        auth: bundle.auth,
        password: req.password,
        resolveTotp: req.resolveTotp,
      );
      if (result.cancelled) {
        return (
          sessionCreated: false,
          error: null,
          needsRollback: needsRollback,
          cancelled: true,
        );
      }
      if (result.result.isError()) {
        return (
          sessionCreated: false,
          error: result.result.exceptionOrNull()!,
          needsRollback: needsRollback,
          cancelled: false,
        );
      }
      return (
        sessionCreated: true,
        error: null,
        needsRollback: false,
        cancelled: false,
      );
    }

    // Non-v6: v5 has no 2FA, so the flag is definitively false.
    if (req.apiVersion != SupportedApiVersions.v6) {
      return (
        sessionCreated: false,
        error: null,
        needsRollback: false,
        cancelled: false,
      );
    }

    // Address changed: new-address credentials were already written, so a
    // failure/cancel needs a rollback.
    if (isAddressChanged) {
      return login(needsRollback: true);
    }

    // Same address, password changed
    if (req.password != req.initPassword) {
      return login(needsRollback: false);
    }

    // Same address, password unchanged
    final probe = await ProbeExistingSession(bundle.dns).run();
    switch (probe) {
      case ExistingSessionValid():
        return (
          sessionCreated: false,
          error: null,
          needsRollback: false,
          cancelled: false,
        );
      case ExistingSessionFailed(:final error):
        return (
          sessionCreated: false,
          error: error,
          needsRollback: false,
          cancelled: false,
        );
      case ExistingSessionNeedsReauth():
        return login(needsRollback: false);
    }
  }

  @override
  void dispose() {
    createServer.removeListener(notifyListeners);
    updateServer.removeListener(notifyListeners);
    super.dispose();
  }
}

/// One run of [AddServerViewModel.updateServer]: rollback, DB commit and
/// cleanup state that all depend on the old and target server addresses.
class _SaveAttempt {
  _SaveAttempt({
    required this.req,
    required this.isAddressChanged,
    required ServersViewModel serversViewModel,
    required StatusViewModel statusViewModel,
    required CreateRepositoryBundle createBundle,
  }) : _serversViewModel = serversViewModel,
       _statusViewModel = statusViewModel,
       _createBundle = createBundle;

  final UpdateServerRequest req;
  final bool isAddressChanged;
  final ServersViewModel _serversViewModel;
  final StatusViewModel _statusViewModel;
  final CreateRepositoryBundle _createBundle;

  String get oldAddress => req.oldServer.address;
  String get targetAddress => isAddressChanged ? req.url : oldAddress;

  void restartAutoRefresh() {
    if (_serversViewModel.selectedServer != null) {
      _statusViewModel.startAutoRefresh();
    }
  }

  /// Restores original credentials only if the edit screen loaded them.
  Future<void> restoreSecrets() async {
    if (req.secretsLoadSucceeded) {
      await _serversViewModel.savePassword(oldAddress, req.initPassword);
      await _serversViewModel.saveToken(oldAddress, req.initToken);
    }
  }

  /// Undoes writes when persisting the new credentials itself failed.
  Future<void> rollbackCredentialWriteFailure() async {
    if (isAddressChanged) {
      await _serversViewModel.deletePassword(targetAddress);
      await _serversViewModel.deleteToken(targetAddress);
      await _serversViewModel.deleteSid(targetAddress);
    } else {
      await restoreSecrets();
    }
  }

  /// Writes [server] to the DB: replace on address change, otherwise edit.
  Future<Object?> commit(Server server) async {
    try {
      if (isAddressChanged) {
        await _serversViewModel.replaceServer.runAsync((
          oldAddress: oldAddress,
          newServer: server,
        ));
        return _serversViewModel.replaceServer.errors.value;
      }
      await _serversViewModel.editServer.runAsync(server);
      return _serversViewModel.editServer.errors.value;
    } catch (e, s) {
      logger.e('Failed to save server', error: e, stackTrace: s);
      return e;
    }
  }

  /// Rolls back artifacts written by this save attempt on failure.
  Future<void> rollback({
    required RepositoryBundle bundle,
    required bool sessionCreated,
  }) async {
    if (isAddressChanged) {
      await _serversViewModel.deletePassword(targetAddress);
      await _serversViewModel.deleteToken(targetAddress);
      await _serversViewModel.deleteSid(targetAddress);
      await _deleteNewSession(bundle, sessionCreated: sessionCreated);
    } else {
      await _deleteNewSession(bundle, sessionCreated: sessionCreated);
      await restoreSecrets();
      // A new same-address SID replaced the previous SID. Drop it so the next
      // request authenticates again. The overwritten remote session expires.
      await _serversViewModel.deleteSid(oldAddress);
    }
  }

  Future<void> _deleteNewSession(
    RepositoryBundle bundle, {
    required bool sessionCreated,
  }) async {
    if (!sessionCreated) return;
    try {
      await bundle.auth.deleteCurrentSession();
    } catch (e, s) {
      logger.w(
        'Failed to delete new session on server',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Cleans up old server state only after the DB commit succeeded.
  Future<void> cleanupAfterCommit() async {
    final oldServer = req.oldServer;
    final oldWasV6 = oldServer.apiVersion == SupportedApiVersions.v6;
    final newIsV6 = req.apiVersion == SupportedApiVersions.v6;

    if (oldWasV6 && (isAddressChanged || !newIsV6)) {
      try {
        final oldBundle = _createBundle(server: oldServer);
        await oldBundle.auth.deleteCurrentSession();
      } catch (e, s) {
        logger.w(
          'Failed to delete old session on server',
          error: e,
          stackTrace: s,
        );
      }
    }

    if (isAddressChanged) {
      await _serversViewModel.deleteToken(oldAddress);
      await _serversViewModel.deletePassword(oldAddress);
      await _serversViewModel.deleteSid(oldAddress);
      _serversViewModel.clearTotpReauthDeclined(oldAddress);
    } else if (oldWasV6 && !newIsV6) {
      await _serversViewModel.deleteSid(targetAddress);
    }
  }
}