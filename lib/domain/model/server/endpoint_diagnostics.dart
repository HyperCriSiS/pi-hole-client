import 'dart:async';
import 'dart:io';

import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/utils/exceptions.dart';

/// These are existing authenticated Pi-hole v6 read-only endpoints.
/// Diagnostics are only run after a deliberate user action.
enum FtlEndpoint {
  host('/api/info/host'),
  sensors('/api/info/sensors'),
  system('/api/info/system'),
  version('/api/info/version');

  const FtlEndpoint(this.path);
  final String path;
}

/// Categories intentionally never contain backend error messages, URLs,
/// credentials or session identifiers.
enum EndpointOutcome {
  success,
  authentication,
  tls,
  timeout,
  connection,
  notFound,
  server,
  unknown,
}

class EndpointCheckResult {
  const EndpointCheckResult({
    required this.endpoint,
    required this.outcome,
    required this.elapsed,
  });

  final FtlEndpoint endpoint;
  final EndpointOutcome outcome;
  final Duration elapsed;
}

/// HTTP responses such as 503/504 may originate from either Pi-hole or a
/// reverse proxy; a failed request is not proof of network unreachability.
EndpointOutcome classifyEndpointError(Object? error) {
  if (error is SidNotFoundException ||
      error is TotpRequiredException ||
      error is TotpInvalidException ||
      error is TotpReusedException ||
      error is TotpCancelledException) {
    return EndpointOutcome.authentication;
  }
  if (error is HandshakeException) return EndpointOutcome.tls;
  if (error is TimeoutException) return EndpointOutcome.timeout;
  if (error is SocketException) return EndpointOutcome.connection;

  final code = switch (error) {
    ApiException e => e.statusCode,
    HttpStatusCodeException e => e.statusCode,
    _ => null,
  };
  return switch (code) {
    401 || 403 => EndpointOutcome.authentication,
    495 => EndpointOutcome.tls,
    504 || 408 => EndpointOutcome.timeout,
    404 => EndpointOutcome.notFound,
    >= 500 => EndpointOutcome.server,
    _ => EndpointOutcome.unknown,
  };
}
