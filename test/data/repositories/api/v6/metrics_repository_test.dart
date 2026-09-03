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

    test('should get stats summary successfully', () async {
      final result = await repository.fetchStatsSummary();
      expect(result.getOrNull(), kRepoFetchStatsSummary);
    });

    test('should fail when fetching stats summary', () async {
      client.shouldFail = true;

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

  group('fetchStatsTopDomains', () {
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

    test('should get blocked stats top domains successfully', () async {
      final result = await repository.fetchStatsTopDomains(blocked: true);
      expect(result.getOrNull(), kRepoFetchStatsTopDomainsBlocked);
    });

    test('should get permitted stats top domains successfully', () async {
      final result = await repository.fetchStatsTopDomains();
      expect(result.getOrNull(), kRepoFetchStatsTopDomains);
    });

    test('should fail when fetching stats top domains', () async {
      client.shouldFail = true;

      final result = await repository.fetchStatsTopDomains();
      expectError(result, messageContains: 'Forced getStatsTopDomains failure');
    });
  });

  group('fetchStatsTopClients', () {
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

    test('should get blocked stats top clients successfully', () async {
      final result = await repository.fetchStatsTopClients(blocked: true);
      expect(result.getOrNull(), kRepoFetchStatsTopClientsBlocked);
    });

    test('should get permitted stats top clients successfully', () async {
      final result = await repository.fetchStatsTopClients();
      expect(result.getOrNull(), kRepoFetchStatsTopClients);
    });

    test('should fail when fetching stats top clients', () async {
      client.shouldFail = true;

      final result = await repository.fetchStatsTopClients();
      expectError(result, messageContains: 'Forced getStatsTopClients failure');
    });
  });

  group('fetchQueryTypes', () {
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

    test('should get query types successfully', () async {
      final result = await repository.fetchQueryTypes();
      expect(result.getOrNull(), kRepoFetchQueryTypes);
    });

    test('should fail when fetching query types', () async {
      client.shouldFail = true;

      final result = await repository.fetchQueryTypes();
      expectError(result, messageContains: 'Forced getQueryTypes failure');
    });
  });

  group('fetchStatsTopDomains', () {
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

    test('should get blocked stats top domains successfully', () async {
      final result = await repository.fetchStatsTopDomains(blocked: true);
      expect(result.getOrNull(), kRepoFetchStatsTopDomainsBlocked);
    });

    test('should get permitted stats top domains successfully', () async {
      final result = await repository.fetchStatsTopDomains();
      expect(result.getOrNull(), kRepoFetchStatsTopDomains);
    });

    test('should fail when fetching stats top domains', () async {
      client.shouldFail = true;

      final result = await repository.fetchStatsTopDomains();
      expectError(result, messageContains: 'Forced getStatsTopDomains failure');
    });
  });

  group('fetchStatsTopClients', () {
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

    test('should get blocked stats top clients successfully', () async {
      final result = await repository.fetchStatsTopClients(blocked: true);
      expect(result.getOrNull(), kRepoFetchStatsTopClientsBlocked);
    });

    test('should get permitted stats top clients successfully', () async {
      final result = await repository.fetchStatsTopClients();
      expect(result.getOrNull(), kRepoFetchStatsTopClients);
    });

    test('should fail when fetching stats top clients', () async {
      client.shouldFail = true;

      final result = await repository.fetchStatsTopClients();
      expectError(result, messageContains: 'Forced getStatsTopClients failure');
    });
  });

  group('fetchQueryTypes', () {
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

    test('should get query types successfully', () async {
      final result = await repository.fetchQueryTypes();
      expect(result.getOrNull(), kRepoFetchQueryTypes);
    });

    test('should fail when fetching query types', () async {
      client.shouldFail = true;

      final result = await repository.fetchQueryTypes();
      expectError(result, messageContains: 'Forced getQueryTypes failure');
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

    test('should get stats overtime successfully', () async {
      final result = await repository.fetchOverTime();
      expect(result.getOrNull(), kRepoFetchOvertime);
    });

    test('should fail when fetching stats over time', () async {
      service.shouldFailHistory = true;

      final result = await repository.fetchOverTime();
      expectError(result, messageContains: 'Forced getHistory failure');
    });
  });
}
