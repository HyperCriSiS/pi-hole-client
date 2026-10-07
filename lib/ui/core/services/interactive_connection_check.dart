import 'package:pi_hole_client/data/repositories/api/interfaces/auth_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/dns_repository.dart';
import 'package:pi_hole_client/domain/model/dns/dns.dart';
import 'package:pi_hole_client/ui/core/services/totp_login.dart';
import 'package:pi_hole_client/ui/core/types/resolve_totp.dart';

enum InteractiveConnectionFailureStage { authentication, blockingStatus }

sealed class InteractiveConnectionCheckOutcome {
  const InteractiveConnectionCheckOutcome();
}

final class InteractiveConnectionCheckSuccess
    extends InteractiveConnectionCheckOutcome {
  const InteractiveConnectionCheckSuccess({
    required this.blocking,
    required this.sessionCreated,
  });

  final Blocking blocking;
  final bool sessionCreated;
}

final class InteractiveConnectionCheckCancelled
    extends InteractiveConnectionCheckOutcome {
  const InteractiveConnectionCheckCancelled();
}

final class InteractiveConnectionCheckFailed
    extends InteractiveConnectionCheckOutcome {
  const InteractiveConnectionCheckFailed({
    required this.error,
    required this.stage,
    required this.sessionCreated,
  });

  final Exception error;
  final InteractiveConnectionFailureStage stage;
  final bool sessionCreated;
}

/// Runs the shared interactive connection verification after the caller has
/// decided whether a new v6 session is required.
///
/// When [loginRequired] is true, this first performs the existing TOTP-aware
/// login flow. A successful login is followed by a blocking-status request with
/// renewal disabled so a transient post-login failure cannot create a duplicate
/// Pi-hole session. Without a new login, the status request keeps normal renewal
/// behavior.
///
/// The caller still owns policy around existing-session probing, rollback, and
/// cleanup. In particular, [sessionCreated] is reported on status failures so an
/// edit flow can delete only a session created by the current save attempt.
Future<InteractiveConnectionCheckOutcome> runInteractiveConnectionCheck({
  required AuthRepository auth,
  required DnsRepository dns,
  required String password,
  required ResolveTotp resolveTotp,
  required bool loginRequired,
}) async {
  var sessionCreated = false;

  if (loginRequired) {
    final login = await runTotpLogin(
      auth: auth,
      password: password,
      resolveTotp: resolveTotp,
    );
    if (login.cancelled) {
      return const InteractiveConnectionCheckCancelled();
    }
    if (login.result.isError()) {
      return InteractiveConnectionCheckFailed(
        error: login.result.exceptionOrNull()!,
        stage: InteractiveConnectionFailureStage.authentication,
        sessionCreated: false,
      );
    }
    sessionCreated = true;
  }

  final result = await dns.fetchBlockingStatus(skipRenewal: sessionCreated);
  if (result.isError()) {
    return InteractiveConnectionCheckFailed(
      error: result.exceptionOrNull()!,
      stage: InteractiveConnectionFailureStage.blockingStatus,
      sessionCreated: sessionCreated,
    );
  }

  return InteractiveConnectionCheckSuccess(
    blocking: result.getOrNull()!,
    sessionCreated: sessionCreated,
  );
}
