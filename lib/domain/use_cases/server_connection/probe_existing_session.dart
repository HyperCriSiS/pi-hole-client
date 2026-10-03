import 'package:pi_hole_client/data/repositories/api/interfaces/dns_repository.dart';
import 'package:pi_hole_client/domain/model/dns/dns.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:result_dart/result_dart.dart';

sealed class ExistingSessionProbeOutcome {
  const ExistingSessionProbeOutcome();
}

final class ExistingSessionValid extends ExistingSessionProbeOutcome {
  const ExistingSessionValid(this.blocking);

  final Blocking blocking;
}

final class ExistingSessionNeedsReauth extends ExistingSessionProbeOutcome {
  const ExistingSessionNeedsReauth();
}

final class ExistingSessionFailed extends ExistingSessionProbeOutcome {
  const ExistingSessionFailed(this.error);

  final Exception error;
}

/// Prüft eine vorhandene Session, ohne sie implizit zu erneuern.
///
/// Nur Authentifizierungsfehler führen zu einer expliziten Neuanmeldung.
/// Transiente Fehler bleiben Fehler, damit sie keine zusätzlichen Sessions
/// auf dem Pi-hole erzeugen.
class ProbeExistingSession {
  const ProbeExistingSession(this._dns);

  final DnsRepository _dns;

  Future<ExistingSessionProbeOutcome> run() async {
    final result = await _dns.fetchBlockingStatus(skipRenewal: true);

    if (result.isSuccess()) {
      return ExistingSessionValid(result.getOrThrow());
    }

    final error =
        result.exceptionOrNull() ?? Exception('Session-Prüfung fehlgeschlagen');
    if (isReauthRequired(error)) {
      return const ExistingSessionNeedsReauth();
    }

    return ExistingSessionFailed(error);
  }
}
