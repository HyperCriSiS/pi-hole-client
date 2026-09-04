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

class _FakePiholeV6Service extends PiholeV6Service {
  _FakePiholeV6Service()
    : super(api: PiholeV6Api(basePathOverride: 'http://localhost/api'));

  bool shouldFailHistory = false;
  bool shouldFailHistoryClients = false;
  bool shouldFailStatsSummary = false;
  String? lastSid;
  int? lastHistoryClientCount;

  @override
  void setSid(String sid) {
    lastSid = sid;
  }

  @override
  Future<Result<GetActivityMetrics200Response>> getHistory() async {
    if (shouldFailHistory) {
      return Failure(Exception('Forced getHistory failure'));
    }
    return Success(
      GetActivityMetrics200Response.fromJson(kSrvGetHistory.toJson()),
    );
  }

  @override
  Future<Result<GetClientMetrics200Response>> getHistoryClients({
    int? count = 10,
  }) async {
    lastHistoryClientCount = count;
    if (shouldFailHistoryClients) {
      return Failure(Exception('Forced getHistoryClients failure'));
    }
    return Success(
      GetClientMetrics200Response.fromJson(kSrvGetHistoryClient.toJson()),
    );
  }

  @override
  Future<Result<GetMetricsSummary200Response>> getStatsSummary() async {
    if (shouldFailStatsSummary) {
      return Failure(Exception('Forced getStatsSummary failure'));
    }
    return Success(
      GetMetricsSummary200Response.fromJson(kSrvGetStatsSummary.toJson()),
    );
  }
}

void main() {
  late MetricsRepositoryV6 repository;
  late FakePiholeV6ApiClient client;
  late FakeSessionCredentialService creds;
  late _FakePiholeV6Service service;

  group('fetchHistory', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = MetricsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should get history successfully through generated service', () async {
      final result = await repository.fetchHistory();

      expect(result.getOrNull(), kRepoFetchHistory);
      expect(service.lastSid, 'sid123');
    });

    test('should fail when generated history request fails', () async {
      service.shouldFailHistory = true;

      final result = await repository.fetchHistory();
      expectError(result, messageContains: 'Forced getHistory failure');
    });
  });

  group('fetchHistoryClient', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = MetricsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should get history client successfully through generated service', () async {
      final result = await repository.fetchHistoryClient();

      expect(result.getOrNull(), kRepoFetchHistoryClient);
      expect(service.lastSid, 'sid123');
      expect(service.lastHistoryClientCount, 10);
    });

    test('should forward custom history client count', () async {
      final result = await repository.fetchHistoryClient(count: 25);

      expect(result.getOrNull(), kRepoFetchHistoryClient);
      expect(service.lastHistoryClientCount, 25);
    });

    test('should allow omitting history client count', () async {
      final result = await repository.fetchHistoryClient(count: null);

      expect(result.getOrNull(), kRepoFetchHistoryClient);
      expect(service.lastHistoryClientCount, isNull);
    });

    test('should fail when generated history client request fails', () async {
      service.shouldFailHistoryClients = true;

      final result = await repository.fetchHistoryClient();
      expectError(result, messageContains: 'Forced getHistoryClients failure');
    });
  });

  group('fetchQueries', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = MetricsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should get queries successfully', () async {
      final result = await repository.fetchQueries(
        from: DateTime.fromMicrosecondsSinceEpoch(1511819900 * 1000),
        until: DateTime.fromMicrosecondsSinceEpoch(1511820500 * 1000),
      );
      expect(result.getOrNull(), kRepoFetchQueries);
    });

    test('should fail when fetching queries', () async {
      client.shouldFail = true;

      final result = await repository.fetchQueries(
        from: DateTime.fromMicrosecondsSinceEpoch(1511819900 * 1000),
        until: DateTime.fromMicrosecondsSinceEpoch(1511820500 * 1000),
      );
      expectError(result, messageContains: 'Forced getQueries failure');
    });
  });

  group('fetchStatsSummary', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = MetricsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test(
      'should get stats summary successfully through generated service',
      () async {
        final result = await repository.fetchStatsSummary();

        expect(result.getOrNull(), kRepoFetchStatsSummary);
        expect(service.lastSid, 'sid123');
      },
    );

    test('should fail when generated stats summary request fails', () async {
      service.shouldFailStatsSummary = true;

      final result = await repository.fetchStatsSummary();
      expectError(result, messageContains: 'Forced getStatsSummary failure');
    });
  });

  group('fetchStatsUpstreams', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = MetricsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should get stats upstreams successfully', () async {
      final result = await repository.fetchStatsUpstreams();
      expect(result.getOrNull(), kRepoFetchStatsUpstreams);
    });

    test('should fail when fetching stats upstreams', () async {
      client.shouldFail = true;

      final result = await repository.fetchStatsUpstreams();
      expectError(result, messageContains: 'Forced getStatsUpstreams failure');
    });
  });

  group('fetchStatsTopDomainsBlocked', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = MetricsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should get stats top domains blocked successfully', () async {
      final result = await repository.fetchStatsTopDomainsBlocked();
      expect(result.getOrNull(), kRepoFetchStatsTopDomainsBlocked);
    });

    test('should fail when fetching stats top domains blocked', () async {
      client.shouldFail = true;

      final result = await repository.fetchStatsTopDomainsBlocked();
      expectError(result, messageContains: 'Forced getStatsTopDomains failure');
    });
  });

  group('fetchStatsTopDomainsAllowed', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = MetricsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should get stats top domains allowed successfully', () async {
      final result = await repository.fetchStatsTopDomainsAllowed();
      expect(result.getOrNull(), kRepoFetchStatsTopDomainsAllowed);
    });

    test('should fail when fetching stats top domains allowed', () async {
      client.shouldFail = true;

      final result = await repository.fetchStatsTopDomainsAllowed();
      expectError(result, messageContains: 'Forced getStatsTopDomains failure');
    });
  });

  group('fetchStatsTopClientsBlocked', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = MetricsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should get stats top clients blocked successfully', () async {
      final result = await repository.fetchStatsTopClientsBlocked();
      expect(result.getOrNull(), kRepoFetchStatsTopClientsBlocked);
    });

    test('should fail when fetching stats top clients blocked', () async {
      client.shouldFail = true;

      final result = await repository.fetchStatsTopClientsBlocked();
      expectError(result, messageContains: 'Forced getStatsTopClients failure');
    });
  });

  group('fetchStatsTopClientsAllowed', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = MetricsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should get stats top clients allowed successfully', () async {
      final result = await repository.fetchStatsTopClientsAllowed();
      expect(result.getOrNull(), kRepoFetchStatsTopClientsAllowed);
    });

    test('should fail when fetching stats top clients allowed', () async {
      client.shouldFail = true;

      final result = await repository.fetchStatsTopClientsAllowed();
      expectError(result, messageContains: 'Forced getStatsTopClients failure');
    });
  });

  group('fetchOverTime', () {
    setUp(() {
      creds = FakeSessionCredentialService();
      client = FakePiholeV6ApiClient();
      service = _FakePiholeV6Service();
      repository = MetricsRepositoryV6(
        client: client,
        service: service,
        sessionCache: V6SessionCache(creds: creds, client: client),
      );
    });

    test('should get overtime successfully', () async {
      final result = await repository.fetchOverTime();
      expect(result.getOrNull(), kRepoFetchOverTime);
    });

    test('should fail when fetching overtime', () async {
      client.shouldFail = true;

      final result = await repository.fetchOverTime();
      expectError(result, messageContains: 'Failed to fetch over time data');
    });
  });
}
