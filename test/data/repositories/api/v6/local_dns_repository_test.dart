import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/local_dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/local_dns/cname_record.dart';
import 'package:pi_hole_client/domain/model/local_dns/local_dns.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailGet = false;
  bool shouldFailPatch = false;
  String? lastSid;
  List<String> hosts = [];
  List<String> cnameRecords = [];
  GetConfig200Response? lastPatchBody;
  bool? lastRestart;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetConfig200Response>> getConfig() async {
    if (shouldFailGet) {
      return Failure(Exception('Forced generated getConfig failure'));
    }
    return Success(
      GetConfig200Response(
        config: ConfigConfig(
          dns: ConfigConfigDns(hosts: hosts, cnameRecords: cnameRecords),
        ),
      ),
    );
  }

  @override
  Future<Result<GetConfig200Response>> patchConfig({
    GetConfig200Response? body,
    bool? restart,
  }) async {
    lastPatchBody = body;
    lastRestart = restart;
    if (shouldFailPatch) {
      return Failure(Exception('Forced generated patchConfig failure'));
    }
    return Success(body ?? GetConfig200Response());
  }
}

void main() {
  late LocalDnsRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _FakePiholeV6Service service;

  LocalDnsRepositoryV6 createRepository() => LocalDnsRepositoryV6(
    client: client,
    service: service,
    sessionCache: V6SessionCache(creds: creds, client: client),
  );

  group('fetchRecords', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = createRepository();
    });

    test('should fetch records successfully', () async {
      final result = await repository.fetchRecords();
      expect(result.isSuccess(), true);
      expect(result.getOrNull(), isEmpty);
      expect(service.lastSid, 'sid123');
    });

    test('should fail when generated config fetch fails', () async {
      service.shouldFailGet = true;
      final result = await repository.fetchRecords();
      expectError(result, messageContains: 'Forced generated getConfig failure');
    });
  });

  group('addRecord', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = createRepository();
    });

    test('should add record successfully', () async {
      final result = await repository.addRecord(
        ip: '192.168.1.100',
        name: 'mydevice',
      );
      expect(result.isSuccess(), true);
    });

    test('should fail when adding record fails', () async {
      client.shouldFail = true;
      final result = await repository.addRecord(
        ip: '192.168.1.100',
        name: 'mydevice',
      );
      expectError(result, messageContains: 'Forced putConfigElement failure');
    });
  });

  group('deleteRecord', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = createRepository();
    });

    test('should delete record successfully', () async {
      final result = await repository.deleteRecord(
        ip: '192.168.1.100',
        name: 'mydevice',
      );
      expect(result.isSuccess(), true);
    });

    test('should fail when deleting record fails', () async {
      client.shouldFail = true;
      final result = await repository.deleteRecord(
        ip: '192.168.1.100',
        name: 'mydevice',
      );
      expectError(
        result,
        messageContains: 'Forced deleteConfigElement failure',
      );
    });
  });

  group('updateRecord', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = createRepository();
    });

    test('should fail when generated current config fetch fails', () async {
      service.shouldFailGet = true;
      final result = await repository.updateRecord(
        record: const LocalDns(ip: '192.168.1.100', name: 'mydevice'),
        oldIp: '192.168.1.1',
      );
      expectError(result, messageContains: 'Forced generated getConfig failure');
    });

    test('should update record through generated config patch', () async {
      service.hosts = ['192.168.1.1 oldname', '192.168.1.2 keep'];

      final result = await repository.updateRecord(
        record: const LocalDns(ip: '192.168.1.100', name: 'newname'),
        oldIp: '192.168.1.1',
      );

      expect(result.isSuccess(), true);
      expect(service.lastRestart, true);
      expect(
        service.lastPatchBody?.config?.dns?.hosts,
        ['192.168.1.100 newname', '192.168.1.2 keep'],
      );
    });

    test('should surface generated record patch errors', () async {
      service.hosts = ['192.168.1.1 oldname'];
      service.shouldFailPatch = true;

      final result = await repository.updateRecord(
        record: const LocalDns(ip: '192.168.1.100', name: 'newname'),
        oldIp: '192.168.1.1',
      );

      expectError(
        result,
        messageContains: 'Forced generated patchConfig failure',
      );
    });

    test('should fail when entry with oldIp is not found in hosts', () async {
      final result = await repository.updateRecord(
        record: const LocalDns(ip: '192.168.1.100', name: 'newname'),
        oldIp: '10.0.0.1',
      );
      expectError(result, messageContains: 'Entry with IP');
    });
  });

  group('CNAME records', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      service = _FakePiholeV6Service();
      repository = createRepository();
    });

    test('should fetch CNAME records successfully', () async {
      final result = await repository.fetchCnameRecords();
      expect(result.isSuccess(), true);
      expect(result.getOrNull(), isEmpty);
    });

    test('should surface generated CNAME fetch errors', () async {
      service.shouldFailGet = true;
      final result = await repository.fetchCnameRecords();
      expectError(result, messageContains: 'Forced generated getConfig failure');
    });

    test('should add CNAME record successfully', () async {
      final result = await repository.addCnameRecord(
        record: const CnameRecord(
          alias: 'printer.example.test',
          target: 'printer.lan',
          ttl: 300,
        ),
      );
      expect(result.isSuccess(), true);
    });

    test('should surface CNAME add errors', () async {
      client.shouldFail = true;
      final result = await repository.addCnameRecord(
        record: const CnameRecord(
          alias: 'printer.example.test',
          target: 'printer.lan',
        ),
      );
      expectError(result, messageContains: 'Forced putConfigElement failure');
    });

    test('should delete CNAME record successfully', () async {
      final result = await repository.deleteCnameRecord(
        record: const CnameRecord(
          alias: 'printer.example.test',
          target: 'printer.lan',
          ttl: 300,
        ),
      );
      expect(result.isSuccess(), true);
    });

    test('should surface CNAME delete errors', () async {
      client.shouldFail = true;
      final result = await repository.deleteCnameRecord(
        record: const CnameRecord(
          alias: 'printer.example.test',
          target: 'printer.lan',
        ),
      );
      expectError(result, messageContains: 'Forced deleteConfigElement failure');
    });

    test('should surface generated CNAME update fetch errors', () async {
      service.shouldFailGet = true;
      final result = await repository.updateCnameRecord(
        oldRecord: const CnameRecord(alias: 'old.example.test', target: 'old.lan'),
        record: const CnameRecord(alias: 'new.example.test', target: 'new.lan'),
      );
      expectError(result, messageContains: 'Forced generated getConfig failure');
    });

    test('should update CNAME through generated config patch', () async {
      service.cnameRecords = [
        'old.example.test,old.lan,300',
        'keep.example.test,keep.lan,600',
      ];

      final result = await repository.updateCnameRecord(
        oldRecord: const CnameRecord(
          alias: 'old.example.test',
          target: 'old.lan',
          ttl: 300,
        ),
        record: const CnameRecord(
          alias: 'new.example.test',
          target: 'new.lan',
          ttl: 450,
        ),
      );

      expect(result.isSuccess(), true);
      expect(service.lastRestart, true);
      expect(
        service.lastPatchBody?.config?.dns?.cnameRecords,
        ['new.example.test,new.lan,450', 'keep.example.test,keep.lan,600'],
      );
    });

    test('should surface generated CNAME patch errors', () async {
      service.cnameRecords = ['old.example.test,old.lan'];
      service.shouldFailPatch = true;

      final result = await repository.updateCnameRecord(
        oldRecord: const CnameRecord(
          alias: 'old.example.test',
          target: 'old.lan',
        ),
        record: const CnameRecord(
          alias: 'new.example.test',
          target: 'new.lan',
        ),
      );

      expectError(
        result,
        messageContains: 'Forced generated patchConfig failure',
      );
    });

    test('should fail update when old CNAME record is absent', () async {
      final result = await repository.updateCnameRecord(
        oldRecord: const CnameRecord(alias: 'old.example.test', target: 'old.lan'),
        record: const CnameRecord(alias: 'new.example.test', target: 'new.lan'),
      );
      expectError(result, messageContains: 'CNAME record');
      expectError(result, messageContains: 'not found');
    });
  });
}
