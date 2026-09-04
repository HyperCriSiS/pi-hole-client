import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/metrics_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/metrics.dart';

class _TopClientsPiholeV6Service extends PiholeV6Service {
  _TopClientsPiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFail = false;
  String? lastSid;
  bool? lastBlocked;
  int? lastCount;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetMetricsTopClients200Response>> getStatsTopClients({
    bool? blocked,
    int? count,
  }) async {
    lastBlocked = blocked;
    lastCount = count;

    if (shouldFail) {
      return Failure(Exception('Forced getStatsTopClients failure'));
    }

    final payload = blocked == true
        ? kSrvGetStatsTopClientsBlocked
        : kSrvGetStatsTopClients;
    return Success(GetMetricsTopClients200Response.fromJson(payload.toJson()));
  }
}

void main() {
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _TopClientsPiholeV6Service service;
  late MetricsRepositoryV6 repository;

  setUp(() {
    client = FakePiholeV6ApiClient();
    creds = FakeSessionCredentialService();
    service = _TopClientsPiholeV6Service();
    repository = MetricsRepositoryV6(
      client: client,
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );
  });

  test('fetches blocked top clients through generated service', () async {
    final result = await repository.fetchStatsTopClientsBlocked();

    expect(result.getOrNull(), kRepoFetchStatsTopClientsBlocked);
    expect(service.lastSid, 'sid123');
    expect(service.lastBlocked, true);
    expect(service.lastCount, 10);
  });

  test('preserves custom and omitted blocked top-client count', () async {
    var result = await repository.fetchStatsTopClientsBlocked(count: 25);

    expect(result.getOrNull(), kRepoFetchStatsTopClientsBlocked);
    expect(service.lastBlocked, true);
    expect(service.lastCount, 25);

    result = await repository.fetchStatsTopClientsBlocked(count: null);

    expect(result.getOrNull(), kRepoFetchStatsTopClientsBlocked);
    expect(service.lastBlocked, true);
    expect(service.lastCount, isNull);
  });

  test('fetches allowed top clients without blocked filter', () async {
    final result = await repository.fetchStatsTopClientsAllowed();

    expect(result.getOrNull(), kRepoFetchStatsTopClientsAllowed);
    expect(service.lastSid, 'sid123');
    expect(service.lastBlocked, isNull);
    expect(service.lastCount, 10);
  });

  test('preserves custom and omitted allowed top-client count', () async {
    var result = await repository.fetchStatsTopClientsAllowed(count: 25);

    expect(result.getOrNull(), kRepoFetchStatsTopClientsAllowed);
    expect(service.lastBlocked, isNull);
    expect(service.lastCount, 25);

    result = await repository.fetchStatsTopClientsAllowed(count: null);

    expect(result.getOrNull(), kRepoFetchStatsTopClientsAllowed);
    expect(service.lastBlocked, isNull);
    expect(service.lastCount, isNull);
  });

  test('propagates generated top-client request failures', () async {
    service.shouldFail = true;

    final result = await repository.fetchStatsTopClientsBlocked();

    expectError(result, messageContains: 'Forced getStatsTopClients failure');
  });
}
