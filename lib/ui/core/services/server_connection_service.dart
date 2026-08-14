import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/repository_bundle.dart';
import 'package:pi_hole_client/domain/model/app/app_log.dart';
import 'package:pi_hole_client/domain/model/dns/dns.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/domain/model/server/api_versions.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';
import 'package:pi_hole_client/ui/core/services/totp_login.dart';
import 'package:pi_hole_client/ui/core/types/resolve_totp.dart';
import 'package:pi_hole_client/ui/core/ui/helpers/globals.dart';
import 'package:pi_hole_client/ui/core/ui/helpers/responsive.dart';
import 'package:pi_hole_client/ui/core/ui/helpers/snackbar.dart';
import 'package:pi_hole_client/ui/core/ui/modals/process_modal.dart';
import 'package:pi_hole_client/ui/core/view_models/app_config_viewmodel.dart';
import 'package:pi_hole_client/ui/core/view_models/servers_viewmodel.dart';
import 'package:pi_hole_client/ui/core/view_models/status_viewmodel.dart';
import 'package:pi_hole_client/ui/servers/widgets/add_server_fullscreen.dart';
import 'package:pi_hole_client/ui/servers/widgets/certificate_details_dialog.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:pi_hole_client/utils/logger.dart';
import 'package:pi_hole_client/utils/tls_certificate.dart';
import 'package:pi_hole_client/utils/widget_channel.dart';
import 'package:result_dart/result_dart.dart';

class ServerConnectionService {
  ServerConnectionService({
    required this.context,
    required this.appConfigViewModel,
    required this.statusViewModel,
    required this.serversViewModel,
    required this.server,
    required this.createBundle,
    required this.resolveTotp,
    this.useRootContextOnFailure = false,
    this.showModal = false,
    this.fetchTlsCertificate = fetchTlsCertificateInfo,
  });

  final BuildContext context;
  final AppConfigViewModel appConfigViewModel;
  final StatusViewModel statusViewModel;
  final ServersViewModel serversViewModel;
  final Server server;
  final CreateRepositoryBundle createBundle;
  final ResolveTotp resolveTotp;
  final bool useRootContextOnFailure;
  final bool showModal;
  final TlsCertificateFetcher fetchTlsCertificate;

  void _recordDiagnostic(String type, String message) {
    appConfigViewModel.addLog(
      AppLog(type: type, dateTime: DateTime.now(), message: message),
    );
  }

  Future<void> connect() async {
    if (serversViewModel.connectingServer == server) return;

    final previouslySelectedServer = serversViewModel.selectedServer;
    final previousStatus = statusViewModel.getServerStatus;
    _startConnection();

    try {
      final serverForLogin = await _ensurePinnedFingerprintIfNeeded(server);
      if (serverForLogin == null) {
        _abortConnection(previouslySelectedServer);
        return;
      }
      if (serversViewModel.connectingServer != server) return;

      final result = await _runLoginQuery(serverForLogin);
      if (serversViewModel.connectingServer != server) return;

      serversViewModel.clearConnectingServer();
      if (result == null || result.isError()) {
        final error = result?.exceptionOrNull();
        if (error is TotpCancelledException) {
          _onTotpCancelled(previouslySelectedServer);
          return;
        }
        _recordDiagnostic(
          'connection',
          'Server connection failed: ${error?.runtimeType ?? 'UnknownError'}: '
              '${error ?? 'No error details available'}',
        );
        await _onFailure(previouslySelectedServer, error, previousStatus);
        return;
      }

      await _onSuccess(result.getOrNull()!, serverForLogin);
    } catch (e, st) {
      logger.e(
        'Unexpected error during server connection',
        error: e,
        stackTrace: st,
      );
      _recordDiagnostic(
        'connection',
        'Unexpected server connection failure: ${e.runtimeType}: $e',
      );
      if (serversViewModel.connectingServer == server) {
        _abortConnection(previouslySelectedServer);
      }
    }
  }

  void _startConnection() {
    serversViewModel.setConnectingServer(server);
    statusViewModel.stopAutoRefresh();
    statusViewModel.setServerStatus(LoadStatus.loading);
  }

  void _abortConnection(Server? fallback) {
    if (serversViewModel.connectingServer != server) return;
    serversViewModel.clearConnectingServer();
    if (fallback != null) {
      serversViewModel.setselectedServer(server: fallback);
      statusViewModel.setServerStatus(LoadStatus.loaded);
      statusViewModel.startAutoRefresh();
    } else {
      statusViewModel.setServerStatus(LoadStatus.error);
    }
  }

  Future<Result<Blocking>?> _runLoginQuery(Server serverForLogin) async {
    ProcessModal? process;
    if (showModal) {
      process = ProcessModal(context: context);
      process.open(AppLocalizations.of(context)!.connecting);
    }

    final bundle = createBundle(server: serverForLogin);
    var sessionJustCreated = false;
    if (serverForLogin.apiVersion == SupportedApiVersions.v6) {
      final creds = await serversViewModel.fetchCredentials(
        serverForLogin.address,
      );
      if (creds.isError()) {
        process?.close();
        final error =
            creds.exceptionOrNull() ?? Exception('Failed to load credentials');
        _recordDiagnostic(
          'secure-storage',
          'Failed to load stored server credentials before connection: '
              '${error.runtimeType}: $error',
        );
        return Failure(error);
      }
      final pw = creds.getOrNull()?.password ?? '';
      if (pw.isNotEmpty) {
        final preCheck = await bundle.dns.fetchBlockingStatus(skipRenewal: true);
        if (preCheck.isSuccess()) {
          process?.close();
          return preCheck;
        }
        final preCheckErr = preCheck.exceptionOrNull();
        if (!isReauthRequired(preCheckErr)) {
          process?.close();
          return Failure(
            preCheckErr ?? Exception('connection pre-check failed'),
          );
        }
        final login = await _createSessionWithTotp(bundle, pw, process);
        if (login.cancelled) {
          process?.close();
          return Failure(TotpCancelledException());
        }
        if (login.error != null) {
          process?.close();
          return Failure(login.error!);
        }
        sessionJustCreated = true;
      }
    }

    final result = await bundle.dns.fetchBlockingStatus(
      skipRenewal: sessionJustCreated,
    );
    process?.close();
    return result;
  }

  Future<({bool cancelled, Exception? error})> _createSessionWithTotp(
    RepositoryBundle bundle,
    String password,
    ProcessModal? process,
  ) async {
    final outcome = await runTotpLogin(
      auth: bundle.auth,
      password: password,
      resolveTotp: ({error}) async {
        process?.close();
        final code = await resolveTotp(error: error);
        if (code != null && context.mounted) {
          process?.open(AppLocalizations.of(context)!.connecting);
        }
        return code;
      },
    );
    final error = outcome.result.exceptionOrNull();
    if (!outcome.cancelled && error != null) {
      _recordDiagnostic(
        'auth',
        'Pi-hole v6 authentication failed: ${error.runtimeType}: $error',
      );
    }
    return (cancelled: outcome.cancelled, error: error);
  }

  Future<void> _onSuccess(Blocking blocking, Server connectedServer) async {
    serversViewModel.clearTotpReauthDeclined(connectedServer.address);
    if (serversViewModel.selectedServer == null &&
        appConfigViewModel.selectedTab == 1) {
      appConfigViewModel.setSelectedTab(4);
    }
    serversViewModel.setselectedServer(server: connectedServer);
    serversViewModel.updateselectedServerStatus(
      blocking.status == DnsBlockingStatus.enabled,
    );
    await WidgetChannel.sendBlockingUpdated(
      serverAddress: connectedServer.address,
    );
    statusViewModel.setServerStatus(LoadStatus.loaded);
    statusViewModel.startAutoRefresh();
  }

  Future<Server?> _ensurePinnedFingerprintIfNeeded(Server server) async {
    if (!context.mounted) return server;
    Uri uri;
    try {
      uri = Uri.parse(server.address);
    } catch (_) {
      return server;
    }

    final pin = server.pinnedCertificateSha256;
    final hasPin = pin != null && pin.trim().isNotEmpty;
    if (uri.scheme != 'https' ||
        server.ignoreCertificateErrors ||
        !server.allowUntrustedCert ||
        hasPin) {
      return server;
    }

    try {
      await fetchTlsCertificate(
        uri,
        allowBadCertificates: false,
        timeout: const Duration(seconds: 3),
      );
      return server;
    } on HandshakeException {
      // Prompt below.
    } catch (_) {
      return server;
    }

    if (!context.mounted) return null;
    return _openUpdatePinnedFingerprint(context, server);
  }

  bool _isSslError(Exception error) {
    return error is HttpStatusCodeException && error.statusCode == 495;
  }

  void _onTotpCancelled(Server? fallback) {
    serversViewModel.markTotpReauthDeclined(server.address);
    if (fallback == null) {
      statusViewModel.setServerStatus(LoadStatus.error);
      return;
    }
    serversViewModel.setselectedServer(server: fallback);
    if (fallback != server) {
      statusViewModel.setServerStatus(LoadStatus.loading);
      statusViewModel.startAutoRefresh();
    } else {
      statusViewModel.setServerStatus(LoadStatus.error);
    }
  }

  Future<void> _onFailure(
    Server? fallback,
    Exception? error,
    LoadStatus previousStatus,
  ) async {
    if (fallback == null) {
      statusViewModel.setServerStatus(LoadStatus.error);
    } else if (previousStatus == LoadStatus.loaded) {
      serversViewModel.setselectedServer(server: fallback);
      statusViewModel.setServerStatus(LoadStatus.loading);
      statusViewModel.startAutoRefresh();
    } else {
      serversViewModel.setselectedServer(server: fallback);
      statusViewModel.setServerStatus(LoadStatus.error);
    }

    if (!context.mounted) {
      if (useRootContextOnFailure) {
        final fallbackContext = globalNavigatorKey.currentContext!;
        showErrorSnackBar(
          context: fallbackContext,
          appConfigViewModel: appConfigViewModel,
          label: AppLocalizations.of(fallbackContext)!.connectionFailed,
        );
      }
      return;
    }

    if (error is HttpStatusCodeException && error.statusCode == 401) {
      showErrorSnackBar(
        context: context,
        appConfigViewModel: appConfigViewModel,
        label: AppLocalizations.of(context)!.wrongPassword,
      );
      return;
    }

    if (error != null && _isSslError(error)) {
      showCautionSnackBar(
        context: context,
        appConfigViewModel: appConfigViewModel,
        label: AppLocalizations.of(context)!.sslError,
      );
      return;
    }

    showErrorSnackBar(
      context: context,
      appConfigViewModel: appConfigViewModel,
      label: AppLocalizations.of(context)!.connectionFailed,
    );
  }

  Future<Server?> _openUpdatePinnedFingerprint(
    BuildContext context,
    Server server,
  ) async {
    final uri = Uri.parse(server.address);
    try {
      final info = await fetchTlsCertificate(
        uri,
        allowBadCertificates: true,
        timeout: const Duration(seconds: 5),
      );
      if (!context.mounted) return null;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (_) => CertificateDetailsDialog(
          certificate: info,
          serverAlias: server.alias,
        ),
      );
      if (accepted != true) return null;
      return server.copyWith(pinnedCertificateSha256: info.sha256Fingerprint);
    } catch (e, st) {
      logger.e('Failed to inspect TLS certificate', error: e, stackTrace: st);
      return null;
    }
  }
}
