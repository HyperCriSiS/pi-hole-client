import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/network_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/network.dart';

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailDeleteDevice = false;
  String? lastSid;
  int? lastDeletedDeviceId;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<Unit>> deleteNetworkDevice({required int deviceId}) async {
    lastDeletedDeviceId = deviceId;
    if (shouldFailDeleteDevice) {
      return Failure(Exception('Forced deleteNetworkDevice failure'));
    }
    return Success(unit);
  }
}

void main() {
  late NetworkRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _FakePiholeV6Service service;

  group('fetchDevices', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = NetworkRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should get devices successfully', () async {
      final result = await repository.fetchDevices();
      expect(result.getOrNull(), kRepoFetchDevices);
    });

    test('should fail when fetching devices', () async {
      client.shouldFail = true;

      final result = await repository.fetchDevices();
      expectError(result, messageContains: 'Forced getNetworkDevices failure');
    });
  });

  group('deleteDevice', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = NetworkRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test(
      'should delete device successfully through generated service',
      () async {
        final result = await repository.deleteDevice(7);

        expectSuccess(result);
        expect(service.lastSid, 'sid123');
        expect(service.lastDeletedDeviceId, 7);
      },
    );

    test('should fail when generated device deletion fails', () async {
      service.shouldFailDeleteDevice = true;

      final result = await repository.deleteDevice(1);
      expectError(
        result,
        messageContains: 'Forced deleteNetworkDevice failure',
      );
    });
  });

  group('fetchGateways', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = NetworkRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should get gateways successfully', () async {
      final result = await repository.fetchGateways();
      expect(result.getOrNull(), kRepoFetchGateways);
    });

    test('should get detailed gateways successfully', () async {
      final result = await repository.fetchGateways(isDetailed: true);
      expect(result.getOrNull(), kRepoFetchGatewaysDetailed);
    });

    test('should fail when fetching gateways', () async {
      client.shouldFail = true;

      final result = await repository.fetchGateways();
      expectError(result, messageContains: 'Forced getNetworkGateway failure');
    });
  });
}
