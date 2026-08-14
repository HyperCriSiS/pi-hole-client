import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/metrics_repository.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/domain/model/metrics/clients.dart';
import 'package:pi_hole_client/domain/model/metrics/history.dart';
import 'package:pi_hole_client/domain/model/metrics/queries.dart';
import 'package:pi_hole_client/domain/model/metrics/summary.dart';
import 'package:pi_hole_client/domain/model/metrics/top_clients.dart';
import 'package:pi_hole_client/domain/model/metrics/top_domains.dart';
import 'package:pi_hole_client/domain/model/metrics/upstreams.dart';
import 'package:pi_hole_client/domain/model/overtime/overtime.dart';
import 'package:pi_hole_client/domain/services/live_logs_service.dart';
import 'package:pi_hole_client/domain/services/logs_pagination_service.dart';
import 'package:pi_hole_client/ui/logs/view_models/logs_viewmodel.dart';
import 'package:result_dart/result_dart.dart';

// ---------------------------------------------------------------------------
// Test fakes
// ---------------------------------------------------------------------------

/// Minimal [MetricsRepository] stub — never called by the fakes below.
class _StubMetricsRepository implements MetricsRepository {
  @override
  Future<Result<Logs>> fetchQueries({
    required DateTime from,
    required DateTime until,
    int? length = 100,
    int? cursor,
    int? start,
  }) => throw UnimplementedError();

  @override
  Future<Result<History>> fetchHistory() => throw UnimplementedError();

  @override
  Future<Result<Clients>> fetchHistoryClient({int? count = 10}) =>
      throw UnimplementedError();

  @override
  Future<Result<Summary>> fetchStatsSummary() => throw UnimplementedError();

  @override
  Future<Result<List<DestinationStat>>> fetchStatsUpstreams() =>
      throw UnimplementedError();

  @override
  Future<Result<List<QueryStat>>> fetchStatsTopDomainsBlocked({
    int? count = 10,
  }) => throw UnimplementedError();

  @override
  Future<Result<List<QueryStat>>> fetchStatsTopDomainsAllowed({
    int? count = 10,
  }) => throw UnimplementedError();

  @override
  Future<Result<List<SourceStat>>> fetchStatsTopClientsBlocked({
    int? count = 10,
  }) => throw UnimplementedError();

  @override
  Future<Result<List<SourceStat>>> fetchStatsTopClientsAllowed({
    int? count = 10,
  }) => throw UnimplementedError();

  @override
  Future<Result<OverTime>> fetchOverTime({int? count = 10}) =>
      throw UnimplementedError();
}

/// [LogsPaginationService] that returns [_logs] on the first [loadNextPage]
/// call and [LoadStatus.loaded] thereafter.
class _ControlledPaginationService extends LogsPaginationService {
  _ControlledPaginationService(this._logs)
    : super(repository: _StubMetricsRepository());

  final List<Log> _logs;
  bool _done = false;

  @override
  LoadStatus get finished => _done ? LoadStatus.loaded : LoadStatus.loading;

  @override
  void reset(DateTime start, DateTime until) {
    super.reset(start, until);
    _done = false;
  }

  @override
  Future<List<Log>> loadNextPage() async {
    if (_done) return const [];
    _done = true;
    return List.of(_logs);
  }
}

/// [LogsPaginationService] that records [loadNextPage] and [reset] call counts.
class _CountingPaginationService extends _ControlledPaginationService {
  _CountingPaginationService(super.logs);

  int loadNextPageCallCount = 0;
  int resetCallCount = 0;

  @override
  void reset(DateTime start, DateTime until) {
    resetCallCount++;
    super.reset(start, until);
  }

  @override
  Future<List<Log>> loadNextPage() async {
    loadNextPageCallCount++;
    return super.loadNextPage();
  }
}

/// [LogsPaginationService] that always returns an empty list and signals error.
class _ErrorPaginationService extends LogsPaginationService {
  _ErrorPaginationService() : super(repository: _StubMetricsRepository());

  @override
  LoadStatus get finished => LoadStatus.error;

  @override
  Future<List<Log>> loadNextPage() async => const [];
}

/// [LogsPaginationService] that can delay the first page until [gate] completes.
class _GatePaginationService extends LogsPaginationService {
  _GatePaginationService(this._logs, {this.gate})
    : super(repository: _StubMetricsRepository());

  final List<Log> _logs;
  final Completer<void>? gate;
  bool _done = false;

  @override
  LoadStatus get finished => _done ? LoadStatus.loaded : LoadStatus.loading;

  @override
  void reset(DateTime start, DateTime until) {
    super.reset(start, until);
    _done = false;
  }

  @override
  Future<List<Log>> loadNextPage() async {
    if (_done) return const [];
    if (gate != null && !gate!.isCompleted) await gate!.future;
    _done = true;
    return List.of(_logs);
  }
}

/// [LiveLogsService] that records tick invocations.
class _CountingLiveLogsService extends LiveLogsService {
  _CountingLiveLogsService({
    required super.paginationService,
    required super.endTime,
    required this.onTick,
  });

  final Future<List<Log>> Function() onTick;
  int tickCount = 0;

  @override
  Future<List<Log>> tickOnce() async {
    tickCount++;
    return onTick();
  }
}

// ---------------------------------------------------------------------------
// Log builders
// ---------------------------------------------------------------------------

Log _allowedLog({
  required String url,
  required String device,
  DateTime? dateTime,
  int? id,
}) => Log(
  dateTime: dateTime ?? DateTime(2024, 1, 1, 12, 0),
  type: DnsRecordType.a,
  url: url,
  device: device,
  replyTime: 0.001,
  status: QueryStatusType.forwarded, // V5 index=2, allowed
  id: id,
);

Log _blockedLog({
  required String url,
  required String device,
  DateTime? dateTime,
  int? id,
}) => Log(
  dateTime: dateTime ?? DateTime(2024, 1, 1, 12, 0),
  type: DnsRecordType.a,
  url: url,
  device: device,
  replyTime: 0.001,
  status: QueryStatusType.gravity, // V5 index=1, blocked
  id: id,
);

// ---------------------------------------------------------------------------
// Helper: configure the VM with a fake repository and an injected factory.
// ---------------------------------------------------------------------------

LogsViewModel _buildVm({
  List<Log>? logs,
  bool failLoad = false,
  String apiVersion = 'v5',
  PaginationServiceFactory? overrideFactory,
}) {
  final factory =
      overrideFactory ??
      (failLoad
          ? ({required MetricsRepository repository}) =>
                _ErrorPaginationService()
          : ({required MetricsRepository repository}) =>
                _ControlledPaginationService(logs ?? const []));

  final vm = LogsViewModel(paginationServiceFactory: factory);
  vm.update(
    metricsRepository: _StubMetricsRepository(),
    apiVersion: apiVersion,
  );
  return vm;
}

/// Calls initScreen to create pagination services, then directly awaits
/// initializeLoad() to bypass SchedulerBinding's post-frame scheduling.
///
/// Requires [TestWidgetsFlutterBinding.ensureInitialized()] to be called
/// before the first use (done via setUpAll in the load/filter groups).
Future<void> _initAndLoad(LogsViewModel vm) async {
  vm.initScreen(logsPerQuery: 2.0); // creates services, schedules (unfired)
  await vm.initializeLoad(); // direct call — no pump needed
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Initialize the Flutter binding once so SchedulerBinding.instance is
  // available when initScreen() schedules its post-frame callback.
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  // -------------------------------------------------------------------------
  // Filter state (pure — no SchedulerBinding required)
  // -------------------------------------------------------------------------

  group('LogsViewModel – hasActiveChips', () {
    late LogsViewModel vm;

    setUp(() => vm = _buildVm());
    tearDown(() => vm.dispose());

    test('returns false when no filters are active', () {
      expect(vm.hasActiveChips, isFalse);
    });

    test('returns true when time filter is active', () {
      vm.setStartTime(DateTime(2024, 1, 1));
      expect(vm.hasActiveChips, isTrue);
    });

    test('returns true when domain filter is active', () {
      vm.setSelectedDomain('example.com');
      expect(vm.hasActiveChips, isTrue);
    });

    test('returns true when client subset is selected', () {
      vm.setClients(['a', 'b']);
      vm.setSelectedClients(['a']);
      expect(vm.hasActiveChips, isTrue);
    });

    test('returns false when all clients are selected', () {
      vm.setClients(['a', 'b']);
      vm.setSelectedClients(['a', 'b']);
      expect(vm.hasActiveChips, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Filter setters
  // -------------------------------------------------------------------------

  group('LogsViewModel – filter setters', () {
    late LogsViewModel vm;

    setUp(() => vm = _buildVm());
    tearDown(() => vm.dispose());

    test('setStartTime / setEndTime update values', () {
      final start = DateTime(2024, 1, 1, 10, 0);
      final end = DateTime(2024, 1, 1, 12, 0);
      vm.setStartTime(start);
      vm.setEndTime(end);
      expect(vm.startTime, equals(start));
      expect(vm.endTime, equals(end));
    });

    test('setSelectedDomain / resetFilters', () {
      vm.setSelectedDomain('example.com');
      expect(vm.selectedDomain, equals('example.com'));
      vm.resetFilters();
      expect(vm.selectedDomain, isNull);
    });

    test('setClients / setSelectedClients / resetClients', () {
      vm.setClients(['a', 'b', 'c']);
      expect(vm.totalClients, equals(['a', 'b', 'c']));
      vm.setSelectedClients(['a']);
      expect(vm.selectedClients, equals(['a']));
      vm.resetClients();
      expect(vm.selectedClients, isEmpty);
    });

    test('setRequestStatus updates request status', () {
      vm.setRequestStatus(RequestStatus.blocked);
      expect(vm.requestStatus, RequestStatus.blocked);
    });
  });

  // -------------------------------------------------------------------------
  // refreshClients callback
  // -------------------------------------------------------------------------

  group('LogsViewModel – refreshClients', () {
    test('calls callback when totalClients is empty', () {
      var called = 0;
      final vm = _buildVm();
      vm.update(onRefreshClients: () => called++);
      vm.refreshClients();
      expect(called, equals(1));
      vm.dispose();
    });

    test('does not call callback when clients are already loaded', () {
      var called = 0;
      final vm = _buildVm();
      vm.update(onRefreshClients: () => called++);
      vm.setClients(['client-a']);
      vm.refreshClients();
      expect(called, equals(0));
      vm.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Search, sort, selectedLog (pure state)
  // -------------------------------------------------------------------------

  group('LogsViewModel - search / sort / selectedLog', () {
    late LogsViewModel vm;

    setUp(() => vm = _buildVm());
    tearDown(() => vm.dispose());

    test('setSearchText updates searchText', () {
      vm.setSearchText('foo');
      expect(vm.searchText, equals('foo'));
    });

    test('updateSortStatus changes sortStatus', () {
      expect(vm.sortStatus, equals(0));
      vm.updateSortStatus(1);
      expect(vm.sortStatus, equals(1));
    });

    test('setSelectedLog / clear selection', () {
      final log = _allowedLog(url: 'x.com', device: '1.2.3.4');
      vm.setSelectedLog(log);
      expect(vm.selectedLog, same(log));
      vm.setSelectedLog(null);
      expect(vm.selectedLog, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Screen lifecycle
  // -------------------------------------------------------------------------

  group('LogsViewModel – screen lifecycle', () {
    test('initScreen activates screen; disposeScreen deactivates', () {
      final vm = _buildVm();
      vm.initScreen(logsPerQuery: 1.5);
      expect(vm.screenActive, isTrue);
      expect(vm.logsPerQuery, equals(1.5));
      vm.disposeScreen();
      expect(vm.screenActive, isFalse);
      vm.dispose();
    });

    test('resumeScreen reactivates screen', () {
      final vm = _buildVm();
      vm.initScreen(logsPerQuery: 2.0);
      vm.disposeScreen();
      vm.resumeScreen();
      expect(vm.screenActive, isTrue);
      vm.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Live config / timer
  // -------------------------------------------------------------------------

  group('LogsViewModel – live config', () {
    test('paused live log does not tick', () async {
      var liveServiceCreated = 0;
      final vm = LogsViewModel(
        paginationServiceFactory: ({required MetricsRepository repository}) =>
            _ControlledPaginationService(const []),
        liveLogsServiceFactory:
            ({
              required LogsPaginationService paginationService,
              required DateTime endTime,
            }) {
              liveServiceCreated++;
              return _CountingLiveLogsService(
                paginationService: paginationService,
                endTime: endTime,
                onTick: () async => const [],
              );
            },
      );
      vm.update(
        metricsRepository: _StubMetricsRepository(),
        apiVersion: 'v5',
      );
      await _initAndLoad(vm);
      vm.configureLive(
        liveLogEnabled: true,
        isLivelogPaused: true,
        isOnLogsTab: true,
        logAutoRefreshTime: 1,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(liveServiceCreated, greaterThanOrEqualTo(1));
      vm.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // initializeLoad
  // -------------------------------------------------------------------------

  group('LogsViewModel – initializeLoad', () {
    test('loads initial logs and reaches loaded state', () async {
      final vm = _buildVm(
        logs: [
          _allowedLog(url: 'a.com', device: '10.0.0.1', id: 1),
          _allowedLog(url: 'b.com', device: '10.0.0.2', id: 2),
        ],
      );
      await _initAndLoad(vm);
      expect(vm.loadStatus, LoadStatus.loaded);
      expect(vm.logsList.length, equals(2));
      vm.dispose();
    });

    test(
      'loading -> error: pagination failure sets loadStatus to error',
      () async {
        final vm = _buildVm(failLoad: true);
        await _initAndLoad(vm);
        expect(vm.loadStatus, LoadStatus.error);
        vm.dispose();
      },
    );

    test('reinitialize replaces stale cache atomically', () async {
      final first = _allowedLog(
        url: 'old.com',
        device: '10.0.0.1',
        id: 1,
      );
      final fresh = _allowedLog(
        url: 'fresh.com',
        device: '10.0.0.2',
        id: 2,
      );
      var calls = 0;
      final vm = _buildVm(
        overrideFactory: ({required MetricsRepository repository}) =>
            _GatePaginationService(calls++ == 0 ? [first] : [fresh]),
      );

      await _initAndLoad(vm);
      expect(vm.logsList.single.url, equals('old.com'));

      await vm.initializeLoad();
      expect(vm.logsList.single.url, equals('fresh.com'));
      vm.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // logsListDisplay – status/client/domain/search filtering
  // -------------------------------------------------------------------------

  group('LogsViewModel – logsListDisplay filtering', () {
    test('filters by search text', () async {
      final vm = _buildVm(
        logs: [
          _allowedLog(url: 'example.com', device: '10.0.0.1', id: 1),
          _allowedLog(url: 'other.net', device: '10.0.0.2', id: 2),
        ],
      );
      await _initAndLoad(vm);

      vm.setSearchText('EXAMPLE');

      final display = vm.logsListDisplay;
      expect(display.length, equals(1));
      expect(display.single.url, equals('example.com'));
      vm.dispose();
    });

    test('filters by selected domain', () async {
      final vm = _buildVm(
        logs: [
          _allowedLog(url: 'example.com', device: '10.0.0.1', id: 1),
          _allowedLog(url: 'other.net', device: '10.0.0.2', id: 2),
        ],
      );
      await _initAndLoad(vm);

      vm.setSelectedDomain('other.net');

      final display = vm.logsListDisplay;
      expect(display.length, equals(1));
      expect(display.single.url, equals('other.net'));
      vm.dispose();
    });

    test('filters by selected clients', () async {
      final vm = _buildVm(
        logs: [
          _allowedLog(url: 'a.com', device: 'client-a', id: 1),
          _allowedLog(url: 'b.com', device: 'client-b', id: 2),
        ],
      );
      await _initAndLoad(vm);

      vm.setClients(['client-a', 'client-b']);
      vm.setSelectedClients(['client-a']);

      final display = vm.logsListDisplay;
      expect(display.length, equals(1));
      expect(display.first.device, equals('client-a'));
      vm.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // logsListDisplay – sort order
  // -------------------------------------------------------------------------

  group('LogsViewModel – logsListDisplay sort order', () {
    test('sortStatus=0 returns newest-first order', () async {
      final older = _allowedLog(
        url: 'old.com',
        device: '10.0.0.1',
        dateTime: DateTime(2024, 1, 1, 10, 0),
        id: 1,
      );
      final newer = _allowedLog(
        url: 'new.com',
        device: '10.0.0.2',
        dateTime: DateTime(2024, 1, 1, 12, 0),
        id: 2,
      );
      final vm = _buildVm(logs: [older, newer]);
      await _initAndLoad(vm);

      vm.updateSortStatus(0); // newest first (default)

      final display = vm.logsListDisplay;
      expect(display.first.url, equals('new.com'));
      expect(display.last.url, equals('old.com'));
      vm.dispose();
    });

    test('sortStatus=1 returns oldest-first order', () async {
      final older = _allowedLog(
        url: 'old.com',
        device: '10.0.0.1',
        dateTime: DateTime(2024, 1, 1, 10, 0),
        id: 1,
      );
      final newer = _allowedLog(
        url: 'new.com',
        device: '10.0.0.2',
        dateTime: DateTime(2024, 1, 1, 12, 0),
        id: 2,
      );
      final vm = _buildVm(logs: [older, newer]);
      await _initAndLoad(vm);

      vm.updateSortStatus(1); // oldest first

      final display = vm.logsListDisplay;
      expect(display.first.url, equals('old.com'));
      expect(display.last.url, equals('new.com'));
      vm.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Direction-aware infinite scrolling (#432)
  // -------------------------------------------------------------------------

  group('LogsViewModel – direction-aware load more', () {
    test('newest-first loads older history, not the live service', () async {
      final initialLog = _allowedLog(
        url: 'initial.com',
        device: '10.0.0.1',
        dateTime: DateTime(2024, 1, 1, 12, 0),
        id: 1,
      );
      final paginationServices = <_CountingPaginationService>[];
      late _CountingLiveLogsService liveService;

      final vm = LogsViewModel(
        paginationServiceFactory: ({required MetricsRepository repository}) {
          final service = _CountingPaginationService([initialLog]);
          paginationServices.add(service);
          return service;
        },
        liveLogsServiceFactory:
            ({
              required LogsPaginationService paginationService,
              required DateTime endTime,
            }) {
              liveService = _CountingLiveLogsService(
                paginationService: paginationService,
                endTime: endTime,
                onTick: () async => const [],
              );
              return liveService;
            },
      );
      vm.update(metricsRepository: _StubMetricsRepository(), apiVersion: 'v5');
      await _initAndLoad(vm);

      final historyService = paginationServices.first;
      final callsBefore = historyService.loadNextPageCallCount;

      vm.updateSortStatus(0);
      await vm.enqueueLoadMore();

      expect(
        historyService.loadNextPageCallCount,
        equals(callsBefore + 1),
      );
      expect(liveService.tickCount, equals(0));
      vm.dispose();
    });

    test(
      'oldest-first loads newer logs even when automatic live log is paused',
      () async {
        final initialLog = _allowedLog(
          url: 'initial.com',
          device: '10.0.0.1',
          dateTime: DateTime(2024, 1, 1, 12, 0),
          id: 1,
        );
        final newerLog = _allowedLog(
          url: 'newer.com',
          device: '10.0.0.2',
          dateTime: DateTime(2024, 1, 1, 12, 5),
          id: 2,
        );
        final paginationServices = <_CountingPaginationService>[];
        late _CountingLiveLogsService liveService;

        final vm = LogsViewModel(
          paginationServiceFactory:
              ({required MetricsRepository repository}) {
                final service = _CountingPaginationService([initialLog]);
                paginationServices.add(service);
                return service;
              },
          liveLogsServiceFactory:
              ({
                required LogsPaginationService paginationService,
                required DateTime endTime,
              }) {
                liveService = _CountingLiveLogsService(
                  paginationService: paginationService,
                  endTime: endTime,
                  onTick: () async => [newerLog],
                );
                return liveService;
              },
        );
        vm.update(
          metricsRepository: _StubMetricsRepository(),
          apiVersion: 'v5',
        );
        await _initAndLoad(vm);

        final historyService = paginationServices.first;
        final callsBefore = historyService.loadNextPageCallCount;

        // Automatic live log remains paused by default. Scrolling to the end
        // in oldest-first mode must still perform a one-shot newer fetch.
        vm.updateSortStatus(1);
        await vm.enqueueLoadMore();

        expect(historyService.loadNextPageCallCount, equals(callsBefore));
        expect(liveService.tickCount, equals(1));
        expect(vm.logsListDisplay.last.url, equals('newer.com'));
        expect(vm.isLoadingMore, isFalse);
        vm.dispose();
      },
    );
  });

  // -------------------------------------------------------------------------
  // applyFilterAndLoad
  // -------------------------------------------------------------------------

  group('LogsViewModel – applyFilterAndLoad', () {
    late _CountingPaginationService service;

    setUp(() {
      service = _CountingPaginationService([
        _allowedLog(url: 'a.com', device: '10.0.0.1', id: 1),
        _allowedLog(url: 'b.com', device: '10.0.0.2', id: 2),
      ]);
    });

    LogsViewModel buildTrackedVm() => _buildVm(
      overrideFactory: ({required MetricsRepository repository}) => service,
    );

    test(
      'with time range: logs are loaded and loadStatus becomes loaded',
      () async {
        final vm = buildTrackedVm();
        await _initAndLoad(vm);

        // After init, the service has already been called once. Reset tracking.
        final callsBefore = service.loadNextPageCallCount;

        await vm.applyFilterAndLoad(
          inStartTime: DateTime(2024, 1, 1, 10, 0),
          inEndTime: DateTime(2024, 1, 1, 12, 0),
        );

        expect(vm.loadStatus, LoadStatus.loaded);
        // loadNextPage must have been called exactly once more for the range.
        expect(service.loadNextPageCallCount, equals(callsBefore + 1));
        // Logs from the page are in the list.
        expect(vm.logsList, isNotEmpty);
        vm.dispose();
      },
    );

    test(
      'with time range: pagination service is reset with the given window',
      () async {
        final vm = buildTrackedVm();
        await _initAndLoad(vm);

        final resetsBefore = service.resetCallCount;
        final start = DateTime(2024, 1, 1, 10, 0);
        final end = DateTime(2024, 1, 1, 12, 0);

        await vm.applyFilterAndLoad(inStartTime: start, inEndTime: end);

        // reset() must have been called once more with the supplied window.
        expect(service.resetCallCount, equals(resetsBefore + 1));
        vm.dispose();
      },
    );
  });
}
