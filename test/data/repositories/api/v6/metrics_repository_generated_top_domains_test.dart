import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/metrics_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/helper/test_helper.dart';
import '../../../../../testing/models/v6/metrics.dart';

class _TopDomainsPiholeV6Service extends PiholeV6Service {
  _TopDomainsPiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFail = false;
  bool failFirstWithUnauthorized = false;
  int callCount = 0;
  String? lastSid;
  bool? lastBlocked;
  int? lastCount;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetMetricsTopDomains200Response>> getStatsTopDomains({
    bool? blocked,
    int? count,
  }) async {
    callCount++;
    lastBlocked = blocked;
    lastCount = count;

    if (failFirstWithUnauthorized && callCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    if (shouldFail) {
      return Failure(Exception('Forced getStatsTopDomains failure'));
    }

    final payload = blocked == true
        ? kSrvGetStatsTopDomainsBlocked
        : kSrvGetStatsTopDomains;
    return Success(GetMetricsTopDomains200Response.fromJson(payload.toJson()));
  }
}

void main() {
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _TopDomainsPiholeV6Service service;
  late MetricsRepositoryV6 repository;

  setUp(() {
    client = FakePiholeV6ApiClient();
    creds = FakeSessionCredentialService();
    service = _TopDomainsPiholeV6Service();
    repository = MetricsRepositoryV6(
      client: client,
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );
  });

  test('fetches blocked top domains through generated service', () async {
    final result = await repository.fetchStatsTopDomainsBlocked();

    expect(result.getOrNull(), kRepoFetchStatsTopDomainsBlocked);
    expect(service.lastSid, 'sid123');
    expect(service.lastBlocked, true);
    expect(service.lastCount, 10);
  });

  test('preserves custom and omitted blocked top-domain count', () async {
    var result = await repository.fetchStatsTopDomainsBlocked(count: 25);

    expect(result.getOrNull(), kRepoFetchStatsTopDomainsBlocked);
    expect(service.lastBlocked, true);
    expect(service.lastCount, 25);

    result = await repository.fetchStatsTopDomainsBlocked(count: null);

    expect(result.getOrNull(), kRepoFetchStatsTopDomainsBlocked);
    expect(service.lastBlocked, true);
    expect(service.lastCount, isNull);
  });

  test('fetches allowed top domains without blocked filter', () async {
    final result = await repository.fetchStatsTopDomainsAllowed();

    expect(result.getOrNull(), kRepoFetchStatsTopDomainsAllowed);
    expect(service.lastSid, 'sid123');
    expect(service.lastBlocked, isNull);
    expect(service.lastCount, 10);
  });

  test('preserves custom and omitted allowed top-domain count', () async {
    var result = await repository.fetchStatsTopDomainsAllowed(count: 25);

    expect(result.getOrNull(), kRepoFetchStatsTopDomainsAllowed);
    expect(service.lastBlocked, isNull);
    expect(service.lastCount, 25);

    result = await repository.fetchStatsTopDomainsAllowed(count: null);

    expect(result.getOrNull(), kRepoFetchStatsTopDomainsAllowed);
    expect(service.lastBlocked, isNull);
    expect(service.lastCount, isNull);
  });

  test('propagates generated top-domain request failures', () async {
    service.shouldFail = true;

    final result = await repository.fetchStatsTopDomainsBlocked();

    expectError(result, messageContains: 'Forced getStatsTopDomains failure');
  });

  test('renews SID and retries blocked top domains after 401', () async {
    service.failFirstWithUnauthorized = true;

    final result = await repository.fetchStatsTopDomainsBlocked(count: 25);

    expect(result.getOrNull(), kRepoFetchStatsTopDomainsBlocked);
    expect(client.postAuthCallCount, 1);
    expect(service.callCount, 2);
    expect(service.lastBlocked, true);
    expect(service.lastCount, 25);
    expect(service.lastSid, isNot('sid123'));
  });
}
