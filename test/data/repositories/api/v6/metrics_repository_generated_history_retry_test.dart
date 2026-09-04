import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/metrics_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart' hide Success;
import 'package:result_dart/result_dart.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';
import '../../../../../testing/models/v6/metrics.dart';

class _RetryPiholeV6Service extends PiholeV6Service {
  _RetryPiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  int getHistoryCallCount = 0;
  int getHistoryClientsCallCount = 0;
  int getStatsSummaryCallCount = 0;
  int getStatsUpstreamsCallCount = 0;
  int? lastHistoryClientCount;
  String? lastSid;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetActivityMetrics200Response>> getHistory() async {
    getHistoryCallCount++;
    if (getHistoryCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(
      GetActivityMetrics200Response.fromJson(kSrvGetHistory.toJson()),
    );
  }

  @override
  Future<Result<GetClientMetrics200Response>> getHistoryClients({
    int? count = 10,
  }) async {
    getHistoryClientsCallCount++;
    lastHistoryClientCount = count;
    if (getHistoryClientsCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(
      GetClientMetrics200Response.fromJson(kSrvGetHistoryClient.toJson()),
    );
  }

  @override
  Future<Result<GetMetricsSummary200Response>> getStatsSummary() async {
    getStatsSummaryCallCount++;
    if (getStatsSummaryCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(
      GetMetricsSummary200Response.fromJson(kSrvGetStatsSummary.toJson()),
    );
  }

  @override
  Future<Result<GetMetricsUpstreams200Response>> getStatsUpstreams() async {
    getStatsUpstreamsCallCount++;
    if (getStatsUpstreamsCallCount == 1) {
      return Failure(ApiException(message: 'Unauthorized', statusCode: 401));
    }
    return Success(
      GetMetricsUpstreams200Response.fromJson(kSrvGetStatsUpstreams.toJson()),
    );
  }
}

void main() {
  test('renews SID and retries generated history service after 401', () async {
    final client = FakePiholeV6ApiClient();
    final creds = FakeSessionCredentialService();
    final service = _RetryPiholeV6Service();
    final repository = MetricsRepositoryV6(
      client: client,
      service: service,
      sessionCache: V6SessionCache(creds: creds, client: client),
    );

    final result = await repository.fetchHistory();

    expect(result.getOrNull(), kRepoFetchHistory);
    expect(client.postAuthCallCount, 1);
    expect(service.getHistoryCallCount, 2);
    expect(service.lastSid, isNot('sid123'));
  });

  test(
    'renews SID and retries generated history clients service after 401',
    () async {
      final client = FakePiholeV6ApiClient();
      final creds = FakeSessionCredentialService();
      final service = _RetryPiholeV6Service();
      final repository = MetricsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );

      final result = await repository.fetchHistoryClient(count: 25);

      expect(result.getOrNull(), kRepoFetchHistoryClient);
      expect(client.postAuthCallCount, 1);
      expect(service.getHistoryClientsCallCount, 2);
      expect(service.lastHistoryClientCount, 25);
      expect(service.lastSid, isNot('sid123'));
    },
  );

  test(
    'renews SID and retries generated stats summary service after 401',
    () async {
      final client = FakePiholeV6ApiClient();
      final creds = FakeSessionCredentialService();
      final service = _RetryPiholeV6Service();
      final repository = MetricsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );

      final result = await repository.fetchStatsSummary();

      expect(result.getOrNull(), kRepoFetchStatsSummary);
      expect(client.postAuthCallCount, 1);
      expect(service.getStatsSummaryCallCount, 2);
      expect(service.lastSid, isNot('sid123'));
    },
  );

  test(
    'renews SID and retries generated stats upstreams service after 401',
    () async {
      final client = FakePiholeV6ApiClient();
      final creds = FakeSessionCredentialService();
      final service = _RetryPiholeV6Service();
      final repository = MetricsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );

      final result = await repository.fetchStatsUpstreams();

      expect(result.getOrNull(), kRepoFetchStatsUpstreams);
      expect(client.postAuthCallCount, 1);
      expect(service.getStatsUpstreamsCallCount, 2);
      expect(service.lastSid, isNot('sid123'));
    },
  );
}
