import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/actions_respository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/actions.dart';

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailFlushLogs = false;
  bool shouldFailRestartDns = false;
  String? lastSid;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<ActionRestartdns200Response>> actionFlushLogs() async {
    if (shouldFailFlushLogs) {
      return Failure(Exception('Forced actionFlushLogs failure'));
    }
    return Success(ActionRestartdns200Response());
  }

  @override
  Future<Result<ActionRestartdns200Response>> actionRestartDns() async {
    if (shouldFailRestartDns) {
      return Failure(Exception('Forced actionRestartDns failure'));
    }
    return Success(ActionRestartdns200Response());
  }
}

void main() {
  late ActionsRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _FakePiholeV6Service service;

  group('flushArp', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = ActionsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should flush ARP successfully', () async {
      final result = await repository.flushArp();
      expectSuccess(result);
    });

    test('retries on failure', () async {
      client.shouldFail = true;

      final result = await repository.flushArp();
      expectError(
        result,
        messageContains: 'Forced postActionFlushNetwork failure',
      );
    });

    test('falls back to flush/arp when flush/network returns 404', () async {
      client.shouldFlushNetworkReturn404 = true;

      final result = await repository.flushArp();
      expectSuccess(result);
    });
  });

  group('flushLogs', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = ActionsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should flush logs successfully through generated service', () async {
      final result = await repository.flushLogs();

      expectSuccess(result);
      expect(service.lastSid, 'sid123');
    });

    test('propagates generated flush-logs failure', () async {
      service.shouldFailFlushLogs = true;

      final result = await repository.flushLogs();
      expectError(result, messageContains: 'Forced actionFlushLogs failure');
    });
  });

  group('updateGravity', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = ActionsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should update gravity successfully', () async {
      final responses = <List<String>>[];

      await for (final res in repository.updateGravity()) {
        responses.add(res.getOrThrow());
      }

      expect(responses.length, kSrvPostActionGravity.length);
      expect(responses, kRepoGravity);
    });

    test('retries on failure', () async {
      client.shouldFail = true;

      final results = <Result<List<String>>>[];
      await for (final res in repository.updateGravity()) {
        results.add(res);
      }

      expect(results.length, 4);
      expectError(
        results.first,
        messageContains: 'Forced postActionGravity failure',
      );
    });
  });

  group('restartDns', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = ActionsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should restart DNS successfully through generated service', () async {
      final result = await repository.restartDns();

      expectSuccess(result);
      expect(service.lastSid, 'sid123');
    });

    test('propagates generated DNS-restart failure', () async {
      service.shouldFailRestartDns = true;

      final result = await repository.restartDns();
      expectError(result, messageContains: 'Forced actionRestartDns failure');
    });
  });
}
