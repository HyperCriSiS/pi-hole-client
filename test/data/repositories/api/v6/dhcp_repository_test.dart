import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/dhcp_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/dhcp.dart';

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailGetDhcpLeases = false;
  bool shouldFailDeleteDhcpLease = false;
  String? lastSid;
  String? lastDeletedIp;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetDhcp200Response>> getDhcpLeases() async {
    if (shouldFailGetDhcpLeases) {
      return Failure(Exception('Forced getDhcpLeases failure'));
    }
    return Success(GetDhcp200Response.fromJson(kSrvGetDhcpLeases.toJson()));
  }

  @override
  Future<Result<Unit>> deleteDhcpLease({required String ip}) async {
    lastDeletedIp = ip;
    if (shouldFailDeleteDhcpLease) {
      return Failure(Exception('Forced deleteDhcpLease failure'));
    }
    return Success(unit);
  }
}

void main() {
  late DhcpRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _FakePiholeV6Service service;

  setUp(() {
    client = FakePiholeV6ApiClient();
    creds = FakeSessionCredentialService();
    service = _FakePiholeV6Service();
    repository = DhcpRepositoryV6(
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );
  });

  group('fetchDhcpLeases', () {
    test('should fetch DHCP leases through generated service', () async {
      final result = await repository.fetchDhcpLeases();

      expect(result.getOrNull(), kRepoFetchDhcpLeases);
      expect(service.lastSid, 'sid123');
    });

    test('should fail when generated DHCP lease fetch fails', () async {
      service.shouldFailGetDhcpLeases = true;

      final result = await repository.fetchDhcpLeases();
      expectError(result, messageContains: 'Forced getDhcpLeases failure');
    });
  });

  group('deleteDhcpLeaseByIp', () {
    test('should delete DHCP lease through generated service', () async {
      final result = await repository.deleteDhcpLeaseByIp('192.168.2.111');

      expectSuccess(result);
      expect(service.lastSid, 'sid123');
      expect(service.lastDeletedIp, '192.168.2.111');
    });

    test('should fail when generated DHCP lease deletion fails', () async {
      service.shouldFailDeleteDhcpLease = true;

      final result = await repository.deleteDhcpLeaseByIp('192.168.2.111');
      expectError(result, messageContains: 'Forced deleteDhcpLease failure');
    });
  });
}
