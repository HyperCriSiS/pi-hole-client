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
import 'package:pi_hole_client/ui/core/services/totp_login.dart';
import 'package:pi_hole_client/ui/core/types/resolve_totp.dart';
import 'package:pi_hole_client/ui/core/view_models/servers_viewmodel.dart';
import 'package:pi_hole_client/ui/core/view_models/status_viewmodel.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
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
  final String initPassword;
  final String initToken;
  final bool secretsLoadSucceeded;
  final ResolveCertificate resolveCertificate;
  final ResolveTotp resolveTotp;
}

sealed class CreateOutcome {
  const CreateOutcome();
}
final class CreateInitial extends CreateOutcome { const CreateInitial(); }
final class CreateSuccess extends CreateOutcome { const CreateSuccess(this.server); final Server server; }
final class CreateCancelled extends CreateOutcome { const CreateCancelled(); }
final class CreateDuplicateUrl extends CreateOutcome { const CreateDuplicateUrl(); }
final class CreateUrlCheckFailed extends CreateOutcome { const CreateUrlCheckFailed(); }
final class CreateApiError extends CreateOutcome { const CreateApiError(this.error, this.version); final Exception error; final String version; }
final class CreateDbError extends CreateOutcome { const CreateDbError(); }

sealed class UpdateOutcome { const UpdateOutcome(); }
final class UpdateInitial extends UpdateOutcome { const UpdateInitial(); }
final class UpdateSuccess extends UpdateOutcome { const UpdateSuccess(); }
final class UpdateCancelled extends UpdateOutcome { const UpdateCancelled(); }
final class UpdateDuplicateUrl extends UpdateOutcome { const UpdateDuplicateUrl(); }
final class UpdateUrlCheckFailed extends UpdateOutcome { const UpdateUrlCheckFailed(); }
final class UpdateApiError extends UpdateOutcome { const UpdateApiError(this.error, this.version); final Exception error; final String version; }
final class UpdateDbError extends UpdateOutcome { const UpdateDbError(); }

enum _UrlCheck { available, duplicate, failed }

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

  Future<_UrlCheck> _checkUrl(String url) async {
    final result = await _serversViewModel.checkUrlExists(url);
    if (result['result'] == 'fail') return _UrlCheck.failed;
    return result['exists'] == true ? _UrlCheck.duplicate : _UrlCheck.available;
  }

  Future<Exception?> _saveCredentials({
    required String address,
    required String password,
    required String token,
  }) async {
    final passwordResult = await _serversViewModel.savePassword(address, password);
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
    final resolved = await req.resolveCertificate(serverObj);
    if (resolved == null) return const CreateCancelled();
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

    final result = await bundle.dns.fetchBlockingStatus(skipRenewal: true);
    if (result.isError()) {
      await _cleanupCreateAttempt(bundle, req);
      return CreateApiError(result.exceptionOrNull()!, req.apiVersion);
    }

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

  Future<void> _cleanupCreateAttempt(
    RepositoryBundle bundle,
    CreateServerRequest req,
  ) async {
    if (req.apiVersion == SupportedApiVersions.v6) {
      await bundle.auth.deleteCurrentSession();
    }
    await _serversViewModel.deletePassword(req.url);
    await _serversViewModel.deleteToken(req.url);
    await _serversViewModel.deleteSid(req.url);
  }

  Future<UpdateOutcome> _updateServer(UpdateServerRequest req) async {
    final oldServer = req.oldServer;
    final oldAddress = oldServer.address;
    final newUrl = req.url;
    final isAddressChanged = !isSameEndpoint(oldAddress, newUrl);

    if (isAddressChanged) {
      switch (await _checkUrl(newUrl)) {
        case _UrlCheck.duplicate:
          return const UpdateDuplicateUrl();
        case _UrlCheck.failed:
          return const UpdateUrlCheckFailed();
        case _UrlCheck.available:
          break;
      }
    }

    final targetAddress = isAddressChanged ? newUrl : oldAddress;

    Future<void> restoreSecrets() async {
      if (req.secretsLoadSucceeded) {
        await _serversViewModel.savePassword(oldAddress, req.initPassword);
        await _serversViewModel.saveToken(oldAddress, req.initToken);
      }
    }

    void restartAutoRefresh() {
      if (_serversViewModel.selectedServer != null) {
        _statusViewModel.startAutoRefresh();
      }
    }

    Future<UpdateOutcome> handleSaveError(Exception e) async {
      await restoreSecrets();
      restartAutoRefresh();
      return UpdateApiError(e, req.apiVersion);
    }

    Future<void> rollbackFailedSave({
      required RepositoryBundle bundle,
      required bool sessionCreated,
    }) async {
      if (isAddressChanged) {
        await _serversViewModel.deletePassword(targetAddress);
        await _serversViewModel.deleteToken(targetAddress);
        await _serversViewModel.deleteSid(targetAddress);
      } else {
        await restoreSecrets();
        if (sessionCreated) {
          await bundle.auth.deleteCurrentSession();
          await _serversViewModel.deleteSid(oldAddress);
        }
      }
    }

    var serverObj = Server(
      address: targetAddress,
      alias: req.alias,
      apiVersion: req.apiVersion,
      allowUntrustedCert: req.allowUntrustedCert,
      ignoreCertificateErrors: req.ignoreCertificateErrors,
      pinnedCertificateSha256: isAddressChanged
          ? null
          : req.pinnedCertificateSha256,
    );

    if (_serversViewModel.selectedServer != null) {
      _statusViewModel.stopAutoRefresh();
    }
    final updatedServer = await req.resolveCertificate(serverObj);
    if (updatedServer == null) {
      restartAutoRefresh();
      return const UpdateCancelled();
    }
    serverObj = updatedServer;

    final credentialError = await _saveCredentials(
      address: targetAddress,
      password: req.password,
      token: req.token,
    );
    if (credentialError != null) {
      if (isAddressChanged) {
        await _serversViewModel.deletePassword(targetAddress);
        await _serversViewModel.deleteToken(targetAddress);
        await _serversViewModel.deleteSid(targetAddress);
      } else {
        await restoreSecrets();
      }
      restartAutoRefresh();
      return const UpdateDbError();
    }

    final bundle = _createBundle(server: serverObj);
    final auth = await _authenticate(
      bundle: bundle,
      req: req,
      isAddressChanged: isAddressChanged,
    );
    if (auth.cancelled) {
      _serversViewModel.markTotpReauthDeclined(targetAddress);
      if (auth.needsRollback) {
        await rollbackFailedSave(bundle: bundle, sessionCreated: false);
      }
      await restoreSecrets();
      restartAutoRefresh();
      return const UpdateCancelled();
    }
    if (auth.error != null) {
      if (auth.needsRollback) {
        await rollbackFailedSave(bundle: bundle, sessionCreated: false);
      }
      return handleSaveError(auth.error!);
    }

    final result = await bundle.dns.fetchBlockingStatus(
      skipRenewal: auth.sessionCreated,
    );
    if (result.isError()) {
      await rollbackFailedSave(
        bundle: bundle,
        sessionCreated: auth.sessionCreated,
      );
      restartAutoRefresh();
      return UpdateApiError(result.exceptionOrNull()!, req.apiVersion);
    }

    final server = serverObj.copyWith(defaultServer: req.defaultServer);
    final cmdError = await _commit(
      server: server,
      oldAddress: oldAddress,
      isAddressChanged: isAddressChanged,
    );
    if (cmdError != null) {
      await rollbackFailedSave(
        bundle: bundle,
        sessionCreated: auth.sessionCreated,
      );
      restartAutoRefresh();
      return const UpdateDbError();
    }

    await _cleanupAfterCommit(
      oldServer: oldServer,
      newApiVersion: req.apiVersion,
      isAddressChanged: isAddressChanged,
      oldAddress: oldAddress,
      targetAddress: targetAddress,
    );
    _serversViewModel.clearTotpReauthDeclined(targetAddress);
    restartAutoRefresh();
    return const UpdateSuccess();
  }

  Future<({bool sessionCreated, Exception? error, bool needsRollback, bool cancelled})>
  _authenticate({
    required RepositoryBundle bundle,
    required UpdateServerRequest req,
    required bool isAddressChanged,
  }) async {
    Future<({bool sessionCreated, Exception? error, bool needsRollback, bool cancelled})>
    login({required bool needsRollback}) async {
      final result = await runTotpLogin(
        auth: bundle.auth,
        password: req.password,
        resolveTotp: req.resolveTotp,
      );
      if (result.cancelled) {
        return (sessionCreated: false, error: null, needsRollback: needsRollback, cancelled: true);
      }
      if (result.result.isError()) {
        return (sessionCreated: false, error: result.result.exceptionOrNull()!, needsRollback: needsRollback, cancelled: false);
      }
      return (sessionCreated: true, error: null, needsRollback: false, cancelled: false);
    }

    if (req.apiVersion != SupportedApiVersions.v6) {
      return (sessionCreated: false, error: null, needsRollback: false, cancelled: false);
    }
    if (isAddressChanged) return login(needsRollback: true);
    if (req.password != req.initPassword) return login(needsRollback: false);

    final preCheck = await bundle.dns.fetchBlockingStatus(skipRenewal: true);
    if (preCheck.isError()) {
      final err = preCheck.exceptionOrNull();
      if (!isReauthRequired(err)) {
        return (sessionCreated: false, error: err, needsRollback: false, cancelled: false);
      }
      return login(needsRollback: false);
    }
    return (sessionCreated: false, error: null, needsRollback: false, cancelled: false);
  }

  Future<Object?> _commit({
    required Server server,
    required String oldAddress,
    required bool isAddressChanged,
  }) async {
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

  Future<void> _cleanupAfterCommit({
    required Server oldServer,
    required String newApiVersion,
    required bool isAddressChanged,
    required String oldAddress,
    required String targetAddress,
  }) async {
    final oldWasV6 = oldServer.apiVersion == SupportedApiVersions.v6;
    final newIsV6 = newApiVersion == SupportedApiVersions.v6;
    if (oldWasV6 && (isAddressChanged || !newIsV6)) {
      try {
        final oldBundle = _createBundle(server: oldServer);
        await oldBundle.auth.deleteCurrentSession();
      } catch (e, s) {
        logger.w('Failed to delete old session on server', error: e, stackTrace: s);
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

  @override
  void dispose() {
    createServer.removeListener(notifyListeners);
    updateServer.removeListener(notifyListeners);
    super.dispose();
  }
}
