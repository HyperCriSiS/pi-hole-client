import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/local_dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/local_dns/local_dns.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';

class _RetryLocalDnsService extends PiholeV6Service {
  _RetryLocalDnsService({
    this.failFirstGet = false,
    this.failFirstPatch = false,
  }) : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  final bool failFirstGet;
  final bool failFirstPatch;

  int getCallCount = 0;
  int patchCallCount = 0;
  String? lastSid;
  List<String> hosts = [];
  GetConfig200Response? lastPatchBody;
  bool? lastRestart;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetConfig200Response>> getConfig() async {
    getCallCount++;
    if (failFirstGet && getCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(
      GetConfig200Response(
        config: ConfigConfig(dns: ConfigConfigDns(hosts: hosts)),
      ),
    );
  }

  @override
  Future<Result<GetConfig200Response>> patchConfig({
    GetConfig200Response? body,
    bool? restart,
  }) async {
    patchCallCount++;
    lastPatchBody = body;
    lastRestart = restart;
    if (failFirstPatch && patchCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(body ?? GetConfig200Response());
  }
}

void main() {
  test('renews SID and retries generated Local DNS read after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryLocalDnsService(failFirstGet: true)
      ..hosts = ['192.168.1.10 printer'];
    final repository = LocalDnsRepositoryV6(
      client: client,
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );

    final result = await repository.fetchRecords();

    expect(result.getOrNull(), const [
      LocalDns(ip: '192.168.1.10', name: 'printer'),
    ]);
    expect(client.postAuthCallCount, 1);
    expect(service.getCallCount, 2);
    expect(service.lastSid, isNot('sid123'));
  });

  test('renews SID and retries generated Local DNS patch after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryLocalDnsService(failFirstPatch: true)
      ..hosts = ['192.168.1.10 oldname'];
    final repository = LocalDnsRepositoryV6(
      client: client,
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );

    final result = await repository.updateRecord(
      record: const LocalDns(ip: '192.168.1.20', name: 'newname'),
      oldIp: '192.168.1.10',
    );

    expect(result.isSuccess(), true);
    expect(client.postAuthCallCount, 1);
    expect(service.getCallCount, 2);
    expect(service.patchCallCount, 2);
    expect(service.lastSid, isNot('sid123'));
    expect(service.lastRestart, true);
    expect(service.lastPatchBody?.config?.dns?.hosts, ['192.168.1.20 newname']);
  });
}
