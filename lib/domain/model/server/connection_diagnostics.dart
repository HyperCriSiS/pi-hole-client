enum ConnectionSessionState {
  notApplicable,
  unknown,
  active,
  noAuthenticationRequired,
  interactiveReauthRequired,
}

enum ConnectionTlsPolicy {
  http,
  httpsVerified,
  httpsPinned,
  httpsUntrustedAllowed,
  httpsCertificateChecksDisabled,
  unknown,
}

class ConnectionDiagnostics {
  const ConnectionDiagnostics({
    required this.apiVersion,
    required this.apiBasePath,
    required this.webPanelPath,
    required this.mfaEnabled,
    required this.sessionState,
    required this.tlsPolicy,
    this.ftlVersion,
  });

  final String apiVersion;
  final String? ftlVersion;
  final String apiBasePath;
  final String webPanelPath;
  final bool? mfaEnabled;
  final ConnectionSessionState sessionState;
  final ConnectionTlsPolicy tlsPolicy;
}
