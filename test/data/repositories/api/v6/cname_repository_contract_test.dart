import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/model/v6/config/config.dart';
import 'package:pi_hole_client/data/repositories/api/v6/local_dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/domain/model/local_dns/cname_record.dart';
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';

class _RecordingPiholeV6ApiClient extends FakePiholeV6ApiClient {
  ConfigData? configData;
  ConfigData? patchBody;
  bool? patchRestart;
  String? putElement;
  String? putValue;
  bool? putRestart;
  String? deleteElement;
  String? deleteValue;
  bool? deleteRestart;

  @override
  Future<Result<Config>> getConfigElement(
    String sid, {
    String? element,
    bool? isDetailed,
  }) async {
    final result = await super.getConfigElement(
      sid,
      element: element,
      isDetailed: isDetailed,
    );
    if (configData == null) return result;
    return result.map((config) => config.copyWith(config: configData));
  }

  @override
  Future<Result<Config>> patchConfig(
    String sid, {
    required ConfigData body,
    bool isRestart = true,
  }) async {
    patchBody = body;
    patchRestart = isRestart;
    return super.patchConfig(sid, body: body, isRestart: isRestart);
  }

  @override
  Future<Result<Unit>> putConfigElement(
    String sid, {
    required String element,
    required String value,
    bool isRestart = true,
  }) async {
    putElement = element;
    putValue = value;
    putRestart = isRestart;
    return super.putConfigElement(
      sid,
      element: element,
      value: value,
      isRestart: isRestart,
    );
  }

  @override
  Future<Result<Unit>> deleteConfigElement(
    String sid, {
    required String element,
    required String value,
    bool isRestart = true,
  }) async {
    deleteElement = element;
    deleteValue = value;
    deleteRestart = isRestart;
    return super.deleteConfigElement(
      sid,
      element: element,
      value: value,
      isRestart: isRestart,
    );
  }
}

void main() {
  late _RecordingPiholeV6ApiClient client;
  late LocalDnsRepositoryV6 repository;

  setUp(() {
    client = _RecordingPiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    repository = LocalDnsRepositoryV6(
      client: client,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );
  });

  test('parses CNAME TTL values from config', () async {
    client.configData = ConfigData(
      dns: Dns(
        cnameRecords: [
          'printer.example.test, printer.lan, 300',
          'nas.example.test,nas.lan',
        ],
      ),
    );

    final result = await repository.fetchCnameRecords();

    expect(result.isSuccess(), true);
    expect(
      result.getOrNull(),
      const [
        CnameRecord(
          alias: 'printer.example.test',
          target: 'printer.lan',
          ttl: 300,
        ),
        CnameRecord(alias: 'nas.example.test', target: 'nas.lan'),
      ],
    );
  });

  test('updates a CNAME and preserves untouched TTL values', () async {
    const oldRecord = CnameRecord(
      alias: 'old.example.test',
      target: 'old.lan',
      ttl: 300,
    );
    const newRecord = CnameRecord(
      alias: 'new.example.test',
      target: 'new.lan',
      ttl: 450,
    );
    client.configData = ConfigData(
      dns: Dns(
        cnameRecords: [
          'old.example.test,old.lan,300',
          'keep.example.test,keep.lan,600',
        ],
      ),
    );

    final result = await repository.updateCnameRecord(
      oldRecord: oldRecord,
      record: newRecord,
    );

    expect(result.isSuccess(), true);
    expect(client.patchRestart, true);
    expect(
      client.patchBody?.dns?.cnameRecords,
      ['new.example.test,new.lan,450', 'keep.example.test,keep.lan,600'],
    );
  });

  test('requests DNS restart for CNAME add and delete', () async {
    const record = CnameRecord(
      alias: 'printer.example.test',
      target: 'printer.lan',
      ttl: 300,
    );

    final addResult = await repository.addCnameRecord(record: record);

    expect(addResult.isSuccess(), true);
    expect(client.putElement, 'dns/cnameRecords');
    expect(client.putValue, 'printer.example.test,printer.lan,300');
    expect(client.putRestart, true);

    final deleteResult = await repository.deleteCnameRecord(record: record);

    expect(deleteResult.isSuccess(), true);
    expect(client.deleteElement, 'dns/cnameRecords');
    expect(client.deleteValue, 'printer.example.test,printer.lan,300');
    expect(client.deleteRestart, true);
  });
}
