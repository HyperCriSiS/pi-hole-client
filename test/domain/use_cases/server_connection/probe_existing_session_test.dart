import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/dns/dns.dart';
import 'package:pi_hole_client/domain/use_cases/server_connection/probe_existing_session.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:result_dart/result_dart.dart';

import '../../../../testing/fakes/repositories/api/fake_dns_repository.dart';

class _RecordingDnsRepository extends FakeDnsRepository {
  final List<bool> skipRenewals = [];

  @override
  Future<Result<Blocking>> fetchBlockingStatus({
    bool skipRenewal = false,
  }) {
    skipRenewals.add(skipRenewal);
    return super.fetchBlockingStatus(skipRenewal: skipRenewal);
  }
}

void main() {
  group('ProbeExistingSession', () {
    late _RecordingDnsRepository dns;

    setUp(() {
      dns = _RecordingDnsRepository();
    });

    test('returns valid for a working existing session', () async {
      final outcome = await ProbeExistingSession(dns).run();

      expect(outcome, isA<ExistingSessionValid>());
      expect(dns.skipRenewals, [true]);
    });

    for (final error in [
      HttpStatusCodeException(401),
      SidNotFoundException(),
    ]) {
      test('requires reauthentication for ${error.runtimeType}', () async {
        dns
          ..shouldFail = true
          ..failureException = error;

        final outcome = await ProbeExistingSession(dns).run();

        expect(outcome, isA<ExistingSessionNeedsReauth>());
        expect(dns.skipRenewals, [true]);
      });
    }

    test('keeps a transient 503 as a failure', () async {
      final error = HttpStatusCodeException(503);
      dns
        ..shouldFail = true
        ..failureException = error;

      final outcome = await ProbeExistingSession(dns).run();

      expect(outcome, isA<ExistingSessionFailed>());
      expect((outcome as ExistingSessionFailed).error, same(error));
      expect(dns.skipRenewals, [true]);
    });
  });
}
