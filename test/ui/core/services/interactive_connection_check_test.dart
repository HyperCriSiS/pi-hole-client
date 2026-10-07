import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/dns/dns.dart';
import 'package:pi_hole_client/ui/core/services/interactive_connection_check.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:result_dart/result_dart.dart';

import '../../../../testing/fakes/repositories/api/fake_auth_repository.dart';
import '../../../../testing/fakes/repositories/api/fake_dns_repository.dart';

class _TrackingDnsRepository extends FakeDnsRepository {
  int fetchCallCount = 0;
  final List<bool> skipRenewalValues = [];

  @override
  Future<Result<Blocking>> fetchBlockingStatus({bool skipRenewal = false}) {
    fetchCallCount++;
    skipRenewalValues.add(skipRenewal);
    return super.fetchBlockingStatus(skipRenewal: skipRenewal);
  }
}

void main() {
  group('runInteractiveConnectionCheck', () {
    late FakeAuthRepository auth;
    late _TrackingDnsRepository dns;

    setUp(() {
      auth = FakeAuthRepository();
      dns = _TrackingDnsRepository();
    });

    test('verifies status without login when login is not required', () async {
      final outcome = await runInteractiveConnectionCheck(
        auth: auth,
        dns: dns,
        password: 'pw',
        resolveTotp: ({error}) async => null,
        loginRequired: false,
      );

      expect(outcome, isA<InteractiveConnectionCheckSuccess>());
      final success = outcome as InteractiveConnectionCheckSuccess;
      expect(success.sessionCreated, isFalse);
      expect(auth.createSessionCallCount, 0);
      expect(dns.fetchCallCount, 1);
      expect(dns.skipRenewalValues, [false]);
    });

    test('new session verifies status with renewal disabled', () async {
      final outcome = await runInteractiveConnectionCheck(
        auth: auth,
        dns: dns,
        password: 'pw',
        resolveTotp: ({error}) async => null,
        loginRequired: true,
      );

      expect(outcome, isA<InteractiveConnectionCheckSuccess>());
      final success = outcome as InteractiveConnectionCheckSuccess;
      expect(success.sessionCreated, isTrue);
      expect(auth.createSessionCallCount, 1);
      expect(dns.fetchCallCount, 1);
      expect(dns.skipRenewalValues, [true]);
    });

    test('cancelled TOTP login does not verify status', () async {
      auth.shouldRequireTotp = true;

      final outcome = await runInteractiveConnectionCheck(
        auth: auth,
        dns: dns,
        password: 'pw',
        resolveTotp: ({error}) async => null,
        loginRequired: true,
      );

      expect(outcome, isA<InteractiveConnectionCheckCancelled>());
      expect(auth.createSessionCallCount, 1);
      expect(dns.fetchCallCount, 0);
    });

    test('authentication failure is reported before status verification', () async {
      auth.shouldFail = true;

      final outcome = await runInteractiveConnectionCheck(
        auth: auth,
        dns: dns,
        password: 'pw',
        resolveTotp: ({error}) async => null,
        loginRequired: true,
      );

      expect(outcome, isA<InteractiveConnectionCheckFailed>());
      final failure = outcome as InteractiveConnectionCheckFailed;
      expect(failure.stage, InteractiveConnectionFailureStage.authentication);
      expect(failure.sessionCreated, isFalse);
      expect(dns.fetchCallCount, 0);
    });

    test('status failure reports that the session was created', () async {
      dns
        ..shouldFail = true
        ..failureException = HttpStatusCodeException(503, 'unavailable');

      final outcome = await runInteractiveConnectionCheck(
        auth: auth,
        dns: dns,
        password: 'pw',
        resolveTotp: ({error}) async => null,
        loginRequired: true,
      );

      expect(outcome, isA<InteractiveConnectionCheckFailed>());
      final failure = outcome as InteractiveConnectionCheckFailed;
      expect(failure.stage, InteractiveConnectionFailureStage.blockingStatus);
      expect(failure.sessionCreated, isTrue);
      expect(dns.fetchCallCount, 1);
      expect(dns.skipRenewalValues, [true]);
    });
  });
}
