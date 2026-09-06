import 'package:pi_hole_client/data/mapper/v6/metrics_mapper.dart';
import 'package:pi_hole_client/data/model/v6/metrics/history.dart' as legacy_history;
import 'package:pi_hole_client/data/model/v6/metrics/query.dart' as legacy_query;
import 'package:pi_hole_client/data/model/v6/metrics/query_filter.dart';
import 'package:pi_hole_client/data/model/v6/metrics/stats.dart' as legacy_stats;
import 'package:pi_hole_client/data/repositories/api/interfaces/metrics_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/base_v6_sid_repository.dart';
import 'package:pi_hole_client/data/repositories/utils/call_with_retry.dart';
import 'package:pi_hole_client/data/services/api/pihole_v6_api_client.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/domain/model/metrics/clients.dart';
import 'package:pi_hole_client/domain/model/metrics/history.dart';
import 'package:pi_hole_client/domain/model/metrics/queries.dart';
import 'package:pi_hole_client/domain/model/metrics/summary.dart';
import 'package:pi_hole_client/domain/model/metrics/top_clients.dart';
import 'package:pi_hole_client/domain/model/metrics/top_domains.dart';
import 'package:pi_hole_client/domain/model/metrics/upstreams.dart';
import 'package:pi_hole_client/domain/model/overtime/overtime.dart';
import 'package:result_dart/result_dart.dart';

class MetricsRepositoryV6 extends BaseV6SidRepository
    implements MetricsRepository, FilteredMetricsRepository {
  MetricsRepositoryV6({
    required PiholeV6ApiClient client,
    required PiholeV6Service service,
    required super.sessionCache,
  }) : _service = service;

  final PiholeV6Service _service;

  @override
  Future<Result<History>> fetchHistory() async {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getHistory();
        return result.map(
          (e) => legacy_history.History.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Clients>> fetchHistoryClient({int? count = 10}) async {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getHistoryClients(count: count);
        return result.map(
          (e) => legacy_history.HistoryClients.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Logs>> fetchQueries({
    required DateTime from,
    required DateTime until,
    int? length = 100,
    int? cursor,
    int? start,
  }) => fetchQueriesFiltered(
    from: from,
    until: until,
    length: length,
    cursor: cursor,
    start: start,
  );

  @override
  Future<Result<Logs>> fetchQueriesFiltered({
    required DateTime from,
    required DateTime until,
    int? length = 100,
    int? cursor,
    int? start,
    V6QueryFilter? filter,
  }) async {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final filterParameters = filter?.toQueryParameters() ?? const {};
        final result = await _service.getQueries(
          from: from.millisecondsSinceEpoch ~/ 1000,
          until: until.millisecondsSinceEpoch ~/ 1000,
          length: length,
          cursor: cursor,
          start: start,
          domain: filterParameters['domain'],
          clientIp: filterParameters['client_ip'],
          status: filterParameters['status'],
          type: filterParameters['type'],
          reply: filterParameters['reply'],
        );

        return result.map(
          (e) => legacy_query.Queries.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<Summary>> fetchStatsSummary() async {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getStatsSummary();
        return result.map(
          (e) => legacy_stats.StatsSummary.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<List<DestinationStat>>> fetchStatsUpstreams() async {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getStatsUpstreams();
        return result.map(
          (e) => legacy_stats.StatsUpstreams.fromJson(e.toJson()).toDomain(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<List<QueryStat>>> fetchStatsTopDomainsBlocked({
    int? count = 10,
  }) async {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getStatsTopDomains(
          count: count,
          blocked: true,
        );
        return result.map(
          (e) => legacy_stats.StatsTopDomains.fromJson(
            e.toJson(),
          ).domains.map((d) => d.toDomain()).toList(),
        );
      },
      onRetry: (_, e) => renewSidIfExpired(e),
    );
  }

  @override
  Future<Result<List<QueryStat>>> fetchStatsTopDomainsAllowed({
    int? count = 10,
  }) async {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getStatsTopDomains(count: count);
        return result.map(
          (e) => legacy_stats.StatsTopDomains.fromJson(
            e.toJson(),
          ).domains.map((d) => d.toDomain()).toList(),
        );
      },
    );
  }

  @override
  Future<Result<List<SourceStat>>> fetchStatsTopClientsBlocked({
    int? count = 10,
  }) async {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getStatsTopClients(
          count: count,
          blocked: true,
        );
        return result.map(
          (e) => legacy_stats.StatsTopClients.fromJson(
            e.toJson(),
          ).clients.map((c) => c.toDomain()).toList(),
        );
      },
    );
  }

  @override
  Future<Result<List<SourceStat>>> fetchStatsTopClientsAllowed({
    int? count = 10,
  }) async {
    return runWithResultRetry(
      action: () async {
        final sid = await getSid();
        _service.setSid(sid);
        final result = await _service.getStatsTopClients(count: count);
        return result.map(
          (e) => legacy_stats.StatsTopClients.fromJson(
            e.toJson(),
          ).clients.map((c) => c.toDomain()).toList(),
        );
      },
    );
  }

  @override
  Future<Result<OverTime>> fetchOverTime({int? count = 10}) async {
    try {
      final response = await Future.wait([
        fetchHistory(),
        fetchHistoryClient(count: count),
      ]);

      final history = response[0] as Result<History>;
      final historyClients = response[1] as Result<Clients>;

      return Success(
        (history.getOrThrow(), historyClients.getOrThrow()).toDomain(),
      );
    } catch (e, st) {
      return Failure(Exception('Failed to fetch over time data: $e\n$st'));
    }
  }
}
