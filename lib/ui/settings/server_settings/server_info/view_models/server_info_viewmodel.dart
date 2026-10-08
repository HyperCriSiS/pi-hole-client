import 'package:command_it/command_it.dart';
import 'package:flutter/foundation.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/auth_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/config_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/ftl_repository.dart';
import 'package:pi_hole_client/domain/model/ftl/pihole_server.dart';
import 'package:pi_hole_client/domain/model/server/api_versions.dart';
import 'package:pi_hole_client/domain/model/server/connection_diagnostics.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';
import 'package:pi_hole_client/utils/url.dart';
import 'package:result_dart/result_dart.dart';

class ServerInfoViewModel extends ChangeNotifier {
  ServerInfoViewModel({
    required FtlRepository ftlRepository,
    required AuthRepository authRepository,
    required ConfigRepository configRepository,
    required Server server,
    ConnectionSessionState Function()? connectionSessionStateProvider,
  }) : _ftlRepository = ftlRepository,
       _authRepository = authRepository,
       _configRepository = configRepository,
       _server = server,
       _connectionSessionStateProvider =
           connectionSessionStateProvider ??
           (() => ConnectionSessionState.unknown) {
    loadServerInfo = Command.createAsyncNoParam<PiholeServer>(
      _loadServerInfo,
      initialValue: const PiholeServer(),
    );
    loadServerInfo.addListener(notifyListeners);
    loadServerInfo.isRunning.addListener(notifyListeners);
    loadServerInfo.errors.addListener(notifyListeners);
  }

  final FtlRepository _ftlRepository;
  final AuthRepository _authRepository;
  final ConfigRepository _configRepository;
  final Server _server;
  final ConnectionSessionState Function() _connectionSessionStateProvider;

  late final Command<void, PiholeServer> loadServerInfo;

  ConnectionDiagnostics? _connectionDiagnostics;

  ConnectionDiagnostics? get connectionDiagnostics => _connectionDiagnostics;

  /// Server 2FA status. `null` when unavailable (e.g. v5).
  bool? get mfaEnabled => _connectionDiagnostics?.mfaEnabled;

  Future<PiholeServer> _loadServerInfo() async {
    final serverFuture = _ftlRepository.fetchAllServerInfo();
    final authFuture = _authRepository.getAuth(useSid: false);
    final webPanelPathsFuture = _configRepository.fetchWebPanelPaths();

    final authResult = await authFuture;
    final mfaEnabled = authResult.getOrNull()?.totp;
    final webPanelPaths = (await webPanelPathsFuture).getOrNull();

    final serverResult = await serverFuture;
    switch (serverResult) {
      case Success():
        final serverInfo = serverResult.getOrThrow();
        _connectionDiagnostics = _buildConnectionDiagnostics(
          serverInfo: serverInfo,
          mfaEnabled: mfaEnabled,
          webPanelPaths: webPanelPaths,
        );
        return serverInfo;
      case Failure():
        throw serverResult.exceptionOrNull();
    }
  }

  ConnectionDiagnostics _buildConnectionDiagnostics({
    required PiholeServer serverInfo,
    required bool? mfaEnabled,
    required WebPanelPaths? webPanelPaths,
  }) {
    final apiEndpoint = _server.apiVersion == SupportedApiVersions.v6
        ? '/api/'
        : '/admin/api.php';
    final apiBasePath = resolveServerUri(_server.address, apiEndpoint).path;
    final webPanelPath = Uri.parse(
      buildWebPanelUrl(
        _server.address,
        prefix: webPanelPaths?.prefix,
        webHome: webPanelPaths?.webHome,
      ),
    ).path;
    final ftlVersion = serverInfo.version?.ftl.local.version;

    return ConnectionDiagnostics(
      apiVersion: _server.apiVersion,
      ftlVersion: ftlVersion == null || ftlVersion.isEmpty ? null : ftlVersion,
      apiBasePath: apiBasePath,
      webPanelPath: webPanelPath,
      mfaEnabled: mfaEnabled,
      sessionState: _connectionSessionStateProvider(),
      tlsPolicy: _resolveTlsPolicy(),
    );
  }

  ConnectionTlsPolicy _resolveTlsPolicy() {
    final scheme = Uri.tryParse(_server.address)?.scheme.toLowerCase();
    if (scheme == 'http') return ConnectionTlsPolicy.http;
    if (scheme != 'https') return ConnectionTlsPolicy.unknown;

    if (_server.ignoreCertificateErrors) {
      return ConnectionTlsPolicy.httpsCertificateChecksDisabled;
    }
    if (_server.allowUntrustedCert) {
      final pin = _server.pinnedCertificateSha256?.trim();
      if (pin != null && pin.isNotEmpty) {
        return ConnectionTlsPolicy.httpsPinned;
      }
      return ConnectionTlsPolicy.httpsUntrustedAllowed;
    }
    return ConnectionTlsPolicy.httpsVerified;
  }

  @override
  void dispose() {
    loadServerInfo.removeListener(notifyListeners);
    loadServerInfo.isRunning.removeListener(notifyListeners);
    loadServerInfo.errors.removeListener(notifyListeners);
    loadServerInfo.dispose();
    super.dispose();
  }
}
