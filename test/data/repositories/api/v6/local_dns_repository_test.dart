import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/local_dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/domain/model/local_dns/cname_record.dart';
import 'package:pi_hole_client/domain/model/local_dns/local_dns.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';

void main() {
  late LocalDnsRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;

  LocalDnsRepositoryV6 createRepository() => LocalDnsRepositoryV6(
    client: client,
    sessionCache: V6SessionCache(creds: creds, client: client),
  );

  group('fetchRecords', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
      repository = createRepository();
    });

    test('should fetch records successfully', () async {
      final result = await repository.fetchRecords();
      expect(result.isSuccess(), true);
      expect(result.getOrNull(), isEmpty);
    });

    test('should fail when fetching config fails', () async {
      client.shouldFail = true;
      final result = await repository.fetchRecords();
      expectError(result, messageContains: 'Forced getConfigElement failure');
    });
  });

  group('addRecord', () {
    setUp(() {
      client = FakePiholeV6ApiClient();
      creds = FakeSessionCredentialService();
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
      repository = createRepository();
    });

    test('should fail when fetching current config fails', () async {
      client.shouldFail = true;
      final result = await repository.updateRecord(
        record: const LocalDns(ip: '192.168.1.100', name: 'mydevice'),
        oldIp: '192.168.1.1',
      );
      expectError(result, messageContains: 'Forced getConfigElement failure');
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
      repository = createRepository();
    });

    test('should fetch CNAME records successfully', () async {
      final result = await repository.fetchCnameRecords();
      expect(result.isSuccess(), true);
      expect(result.getOrNull(), isEmpty);
    });

    test('should surface CNAME fetch errors', () async {
      client.shouldFail = true;
      final result = await repository.fetchCnameRecords();
      expectError(result, messageContains: 'Forced getConfigElement failure');
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

    test('should surface CNAME update fetch errors', () async {
      client.shouldFail = true;
      final result = await repository.updateCnameRecord(
        oldRecord: const CnameRecord(alias: 'old.example.test', target: 'old.lan'),
        record: const CnameRecord(alias: 'new.example.test', target: 'new.lan'),
      );
      expectError(result, messageContains: 'Forced getConfigElement failure');
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
