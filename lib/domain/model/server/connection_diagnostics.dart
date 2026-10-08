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

/// Result of the existing FTL server-info request, not a standalone ping.
///
/// A failed authenticated request does not by itself prove the host is offline.
class FtlRequestDiagnostic {
  const FtlRequestDiagnostic({
    required this.succeeded,
    required this.elapsed,
  });

  final bool succeeded;
  final Duration elapsed;
}
