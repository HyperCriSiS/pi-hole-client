import 'dart:async';

import 'package:pi_hole_client/utils/exceptions.dart';

/// Advisory only. A timeout cannot identify a specific proxy or prove
/// buffering; the UI must state the conditions under which the hint applies.
enum GravityStreamHint { possibleProxyBuffering }

/// A response-header timeout before any gravity progress is consistent with
/// nginx buffering the upstream streaming response (upstream issue #754).
/// Other causes remain possible. Never classify auth, TLS, arbitrary errors,
/// or failures after receiving progress as nginx-specific.
GravityStreamHint? diagnoseGravityStreamFailure(
  Object error, {
  required bool hasProgress,
}) {
  if (hasProgress) return null;
  if (error is TimeoutException ||
      (error is HttpStatusCodeException && error.statusCode == 504)) {
    return GravityStreamHint.possibleProxyBuffering;
  }
  return null;
}
