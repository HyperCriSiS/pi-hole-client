import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/model/v6/metrics/query_filter.dart';
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
  bool shouldFailQueries = false;
  bool shouldFailStatsSummary = false;
  bool shouldFailStatsUpstreams = false;
  bool shouldFailStatsTopDomains = false;
  bool shouldFailStatsTopClients = false;
  String? lastSid;
  int? lastHistoryClientCount;
  num? lastQueriesFrom;
  num? lastQueriesUntil;
  int? lastQueriesLength;
  int? lastQueriesStart;
  int? lastQueriesCursor;
  String? lastQueriesDomain;
  String? lastQueriesClientIp;
  String? lastQueriesClientName;
  String? lastQueriesUpstream;
  String? lastQueriesType;
  String? lastQueriesStatus;
  String? lastQueriesReply;
  String? lastQueriesDnssec;

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
  Future<Result<GetQueries200Response>> getQueries({
    num? from,
    num? until,
    int? length,
    int? start,
    int? cursor,
    String? domain,
    String? clientIp,
    String? clientName,
    String? upstream,
    String? type,
    String? status,
    String? reply,
    String? dnssec,
  }) async {
    lastQueriesFrom = from;
    lastQueriesUntil = until;
    lastQueriesLength = length;
    lastQueriesStart = start;
    lastQueriesCursor = cursor;
    lastQueriesDomain = domain;
    lastQueriesClientIp = clientIp;
    lastQueriesClientName = clientName;
    lastQueriesUpstream = upstream;
    lastQueriesType = type;
    lastQueriesStatus = status;
    lastQueriesReply = reply;
    lastQueriesDnssec = dnssec;
    if (shouldFailQueries) {
      return Failure(Exception('Forced getQueries failure'));
    }
    final json = jsonDecode(jsonEncode(kSrvGetQueries.toJson()));
    return Success(
      GetQueries200Response.fromJson(json as Map<String, dynamic>),
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

  @override
  Future<Result<GetMetricsUpstreams200Response>> getStatsUpstreams() async {
    if (shouldFailStatsUpstreams) {
      return Failure(Exception('Forced getStatsUpstreams failure'));
    }
    return Success(
      GetMetricsUpstreams200Response.fromJson(kSrvGetStatsUpstreams.toJson()),
    );
  }

  @override
  Future<Result<GetMetricsTopDomains200Response>> getStatsTopDomains({
    bool? blocked,
    int? count,
  }) async {
    if (shouldFailStatsTopDomains) {
      return Failure(Exception('Forced getStatsTopDomains failure'));
    }
    final payload = blocked == true
        ? kSrvGetStatsTopDomainsBlocked
        : kSrvGetStatsTopDomains;
    return Success(GetMetricsTopDomains200Response.fromJson(payload.toJson()));
  }

  @override
  Future<Result<GetMetricsTopClients200Response>> getStatsTopClients({
    bool? blocked,
    int? count,
  }) async {
    if (shouldFailStatsTopClients) {
      return Failure(Exception('Forced getStatsTopClients failure'));
    }
    final payload = blocked == true
        ? kSrvGetStatsTopClientsBlocked
        : kSrvGetStatsTopClients;
    return Success(GetMetricsTopClients200Response.fromJson(payload.toJson()));
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

    test(
      'should get history client successfully through generated service',
      () async {
        final result = await repository.fetchHistoryClient();

        expect(result.getOrNull(), kRepoFetchHistoryClient);
        expect(service.lastSid, 'sid123');
        expect(service.lastHistoryClientCount, 10);
      },
    );

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

    test('gets queries successfully through generated service', () async {
      final result = await repository.fetchQueries(
        from: DateTime.fromMillisecondsSinceEpoch(1511819900123),
        until: DateTime.fromMillisecondsSinceEpoch(1511820500987),
        length: 25,
        cursor: 42,
        start: 10,
      );

      expect(result.getOrNull(), kRepoFetchQueries);
      expect(service.lastSid, 'sid123');
      expect(service.lastQueriesFrom, 1511819900);
      expect(service.lastQueriesUntil, 1511820500);
      expect(service.lastQueriesLength, 25);
      expect(service.lastQueriesCursor, 42);
      expect(service.lastQueriesStart, 10);
    });

    test('forwards supported v6 query filters to generated service', () async {
      final result = await repository.fetchQueriesFiltered(
        from: DateTime.fromMillisecondsSinceEpoch(1511819900000),
        until: DateTime.fromMillisecondsSinceEpoch(1511820500000),
        filter: const V6QueryFilter(
          domain: ' example.com ',
          clientIp: ' 192.0.2.10 ',
          status: ' FORWARDED ',
          type: ' AAAA ',
          reply: ' IP ',
        ),
      );

      expect(result.getOrNull(), kRepoFetchQueries);
      expect(service.lastQueriesDomain, 'example.com');
      expect(service.lastQueriesClientIp, '192.0.2.10');
      expect(service.lastQueriesStatus, 'FORWARDED');
      expect(service.lastQueriesType, 'AAAA');
      expect(service.lastQueriesReply, 'IP');
      expect(service.lastQueriesClientName, isNull);
      expect(service.lastQueriesUpstream, isNull);
      expect(service.lastQueriesDnssec, isNull);
    });

    test('omits empty v6 query filters', () async {
      final result = await repository.fetchQueriesFiltered(
        from: DateTime.fromMillisecondsSinceEpoch(1511819900000),
        until: DateTime.fromMillisecondsSinceEpoch(1511820500000),
        filter: const V6QueryFilter(domain: ' ', clientIp: ''),
      );

      expect(result.getOrNull(), kRepoFetchQueries);
      expect(service.lastQueriesDomain, isNull);
      expect(service.lastQueriesClientIp, isNull);
    });

    test('fails when generated query request fails', () async {
      service.shouldFailQueries = true;

      final result = await repository.fetchQueries(
        from: DateTime.fromMillisecondsSinceEpoch(1511819900000),
        until: DateTime.fromMillisecondsSinceEpoch(1511820500000),
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

    test(
      'should get stats upstreams successfully through generated service',
      () async {
        final result = await repository.fetchStatsUpstreams();

        expect(result.getOrNull(), kRepoFetchStatsUpstreams);
        expect(service.lastSid, 'sid123');
      },
    );

    test('should fail when generated stats upstreams request fails', () async {
      service.shouldFailStatsUpstreams = true;

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
      service.shouldFailStatsTopDomains = true;

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
      service.shouldFailStatsTopDomains = true;

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
      service.shouldFailStatsTopClients = true;

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
      service.shouldFailStatsTopClients = true;

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

    test('should get stats over time successfully', () async {
      final result = await repository.fetchOverTime();
      expect(result.getOrNull(), kRepoFetchOverTime);
    });

    test('should fail when fetching stats over time', () async {
      service.shouldFailHistory = true;

      final result = await repository.fetchOverTime();
      expectError(result, messageContains: 'Forced getHistory failure');
    });
  });
}
