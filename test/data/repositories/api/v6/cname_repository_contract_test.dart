import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/local_dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/local_dns/cname_record.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';

class _RecordingPiholeV6ApiClient extends FakePiholeV6ApiClient {
  String? putElement;
  String? putValue;
  bool? putRestart;
  String? deleteElement;
  String? deleteValue;
  bool? deleteRestart;

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

class _RecordingPiholeV6Service extends PiholeV6Service {
  _RecordingPiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  List<String> cnameRecords = [];
  GetConfig200Response? patchBody;
  bool? patchRestart;
  String? lastSid;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetConfig200Response>> getConfig() async {
    return Success(
      GetConfig200Response(
        config: ConfigConfig(
          dns: ConfigConfigDns(cnameRecords: cnameRecords),
        ),
      ),
    );
  }

  @override
  Future<Result<GetConfig200Response>> patchConfig({
    GetConfig200Response? body,
    bool? restart,
  }) async {
    patchBody = body;
    patchRestart = restart;
    return Success(body ?? GetConfig200Response());
  }
}

void main() {
  late _RecordingPiholeV6ApiClient client;
  late _RecordingPiholeV6Service service;
  late LocalDnsRepositoryV6 repository;

  setUp(() {
    client = _RecordingPiholeV6ApiClient();
    service = _RecordingPiholeV6Service();
    final creds = FakeSessionCredentialService();
    repository = LocalDnsRepositoryV6(
      client: client,
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );
  });

  test('parses CNAME TTL values from config', () async {
    service.cnameRecords = [
      'printer.example.test, printer.lan, 300',
      'nas.example.test,nas.lan',
    ];

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
    service.cnameRecords = [
      'old.example.test,old.lan,300',
      'keep.example.test,keep.lan,600',
    ];

    final result = await repository.updateCnameRecord(
      oldRecord: oldRecord,
      record: newRecord,
    );

    expect(result.isSuccess(), true);
    expect(service.patchRestart, true);
    expect(
      service.patchBody?.config?.dns?.cnameRecords,
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
