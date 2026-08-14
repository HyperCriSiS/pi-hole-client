import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/ftl_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/metrics_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/realtime_status_repository.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/domain/model/ftl/metrics.dart';
import 'package:pi_hole_client/domain/model/ftl/sensor.dart';
import 'package:pi_hole_client/domain/model/ftl/system.dart';
import 'package:pi_hole_client/domain/model/overtime/overtime.dart';
import 'package:pi_hole_client/domain/model/realtime_status/realtime_status.dart';
import 'package:pi_hole_client/domain/model/server/api_versions.dart';
import 'package:pi_hole_client/domain/services/app_log_service.dart';
import 'package:pi_hole_client/domain/use_cases/realtime_status/realtime_status_usecase.dart';
import 'package:pi_hole_client/domain/use_cases/realtime_status/realtime_status_usecase_v5.dart';
import 'package:pi_hole_client/domain/use_cases/realtime_status/realtime_status_usecase_v6.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:pi_hole_client/utils/logger.dart';
import 'package:pi_hole_client/utils/widget_channel.dart';

/// ViewModel for the Home and Statistics screens.
///
/// Manages periodic polling of Pi-hole server status data (realtime status,
/// overtime charts, FTL metrics) and exposes the cached results to the UI.
///
/// Replaces the former `StatusUpdateService` + dumb `StatusViewModel` pair.
/// All timer/fetch logic now lives here; ViewModel->ViewModel communication
/// is eliminated via value + callback injection through [update].
class StatusViewModel with ChangeNotifier {
  StatusViewModel({AppLogService? appLogService})
    : _appLogService = appLogService;

  final AppLogService? _appLogService;

  void _recordConnectionFailure(String stage, Object? error) {
    _appLogService?.addDiagnostic(
      type: 'connection',
      message:
          '$stage failed: ${error?.runtimeType ?? 'UnknownError'}: '
          '${error ?? 'No error details available'}',
    );
  }

  // ---------------------------------------------------------------------------
  // Dependencies (injected via [update] from ProxyProvider)
  // ---------------------------------------------------------------------------
  RealtimeStatusRepository? _realtimeStatusRepository;
  MetricsRepository? _metricsRepository;
  DnsRepository? _dnsRepository;
  FtlRepository? _ftlRepository;
  String? _apiVersion;

  // Values extracted from ServersViewModel / AppConfigViewModel.
  // No ViewModel references are held — only primitive values + callbacks.
  String? _selectedServerAddress;
  String? _selectedServerAlias;
  bool _isConnecting = false;
  int? _autoRefreshTime;
  void Function(bool)? _onUpdateServerStatus;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  LoadStatus _serverStatus = LoadStatus.loading;
  LoadStatus _statusLoading = LoadStatus.loading;
  LoadStatus _overtimeDataLoading = LoadStatus.loading;
  RealtimeStatus? _realtimeStatus;
  OverTime? _overtimeData;
  FtlDnsMetrics? _ftlDnsMetrics;
  FtlSystem? _ftlSystem;
  FtlSensor? _ftlSensor;

  // ---------------------------------------------------------------------------
  // Timer management
  // ---------------------------------------------------------------------------
  Timer? _statusDataTimer;
  Timer? _overTimeDataTimer;
  Timer? _metricsDataTimer;
  bool _isAutoRefreshRunning = false;
  bool _isStatusFetchInProgress = false;
  bool _isOvertimeFetchInProgress = false;
  bool _isMetricsFetchInProgress = false;

  // Fatal error surfaced to the shell for interactive recovery (e.g. TLS pin
  // mismatch or TOTP required). Consumed via [consumeFatalConnectionError].
  Exception? _fatalConnectionError;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------
  LoadStatus get getServerStatus => _serverStatus;
  LoadStatus get getStatusLoading => _statusLoading;
  LoadStatus get getOvertimeDataLoading => _overtimeDataLoading;
  RealtimeStatus? get realtimeStatus => _realtimeStatus;
  OverTime? get overTimeData => _overtimeData;
  FtlDnsMetrics? get ftlDnsMetrics => _ftlDnsMetrics;
  FtlSystem? get ftlSystem => _ftlSystem;
  FtlSensor? get ftlSensor => _ftlSensor;
  bool get isAutoRefreshRunning => _isAutoRefreshRunning;

  /// Returns and clears a pending fatal connection error.
  Exception? consumeFatalConnectionError() {
    final error = _fatalConnectionError;
    _fatalConnectionError = null;
    return error;
  }

  /// Derived top client names for filter UI. Replaces the former push-based
  /// `FiltersViewModel.setClients()` call in `StatusUpdateService`.
  List<String> get topClientNames {
    final clients = _realtimeStatus?.topClients ?? [];
    return clients.map((c) => c.name).toList();
  }

  // ---------------------------------------------------------------------------
  // Dependency update (called by ProxyProvider)
  // ---------------------------------------------------------------------------

  /// Updates repository dependencies and primitive configuration values.
  ///
  /// Called by `ChangeNotifierProxyProvider4` from [dependencies.dart] whenever
  /// the selected server or app config changes.
  void update({
    RealtimeStatusRepository? realtimeStatusRepository,
    MetricsRepository? metricsRepository,
    DnsRepository? dnsRepository,
    FtlRepository? ftlRepository,
    String? apiVersion,
    String? selectedServerAddress,
    String? selectedServerAlias,
    bool? isConnecting,
    int? autoRefreshTime,
    void Function(bool)? onUpdateServerStatus,
  }) {
    final serverChanged = selectedServerAddress != _selectedServerAddress;
    _realtimeStatusRepository = realtimeStatusRepository;
    _metricsRepository = metricsRepository;
    _dnsRepository = dnsRepository;
    _ftlRepository = ftlRepository;
    _apiVersion = apiVersion;
    _selectedServerAddress = selectedServerAddress;
    _selectedServerAlias = selectedServerAlias;
    _isConnecting = isConnecting ?? false;
    _autoRefreshTime = autoRefreshTime;
    _onUpdateServerStatus = onUpdateServerStatus;

    if (serverChanged) {
      // Reset stale data so a previous server's status is never shown while the
      // newly selected one is loading.
      _realtimeStatus = null;
      _overtimeData = null;
      _ftlDnsMetrics = null;
      _ftlSystem = null;
      _ftlSensor = null;
      _serverStatus = LoadStatus.loading;
      _statusLoading = LoadStatus.loading;
      _overtimeDataLoading = LoadStatus.loading;
      _fatalConnectionError = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Public state setters
  // ---------------------------------------------------------------------------

  void setServerStatus(LoadStatus status) {
    if (_serverStatus != status) {
      _serverStatus = status;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Auto-refresh lifecycle
  // ---------------------------------------------------------------------------

  /// Starts (or restarts) all status polling timers.
  ///
  /// [runImmediately] triggers the first fetch synchronously before scheduling
  /// the timer. [isDelay] delays overtime/metrics on resume to reduce bursts.
  void startAutoRefresh({bool runImmediately = true, bool isDelay = false}) {
    if (_selectedServerAddress == null) return;
    _stopAutoRefresh(showLoadingIndicator: false);
    _isAutoRefreshRunning = true;
    _serverStatus = LoadStatus.loading;
    _statusLoading = LoadStatus.loading;
    _overtimeDataLoading = LoadStatus.loading;
    notifyListeners();

    _setupStatusDataTimer(runImmediately: runImmediately);
    _setupOverTimeDataTimer(runImmediately: runImmediately, isDelay: isDelay);
    _setupMetricsDataTimer(runImmediately: runImmediately, isDelay: isDelay);
  }

  /// Stops polling timers. When [showLoadingIndicator] is true (default),
  /// loading indicators are shown until the next connection starts.
  void stopAutoRefresh({bool showLoadingIndicator = true}) {
    _stopAutoRefresh(showLoadingIndicator: showLoadingIndicator);
  }

  /// One-shot refresh used by pull-to-refresh and resume.
  Future<bool> refreshOnce() => _refreshOnce();

  /// Whether the given error is a TLS certificate mismatch (HTTP 495).
  bool _isSslError(Object? error) =>
      error is HttpStatusCodeException && error.statusCode == 495;

  // Stops auto-refresh and signals the UI on a fatal connection error that
  // needs interactive recovery: a TLS error (pin mismatch) or a 2FA server
  // requiring a TOTP code (TotpRequiredException).
  bool _handleFatalConnectionError(Object? error, String? selectedUrlBefore) {
    final isFatal = _isSslError(error) || error is TotpRequiredException;
    if (!isFatal || selectedUrlBefore != _selectedServerAddress) {
      return false;
    }
    _recordConnectionFailure('Fatal status refresh', error);
    logger.w(
      'Fatal connection error during status refresh; '
      'stopping auto-refresh: $error',
    );
    _serverStatus = LoadStatus.error;
    _statusLoading = LoadStatus.error;
    _stopAutoRefresh(showLoadingIndicator: false);
    _fatalConnectionError = error is Exception
        ? error
        : Exception(error.toString());
    notifyListeners();
    return true;
  }

  void _stopAutoRefresh({bool showLoadingIndicator = true}) {
    if (showLoadingIndicator) {
      _statusLoading = LoadStatus.loading;
      _overtimeDataLoading = LoadStatus.loading;
      notifyListeners();
    }

    _isAutoRefreshRunning = false;
    _statusDataTimer?.cancel();
    _overTimeDataTimer?.cancel();
    _metricsDataTimer?.cancel();
    _statusDataTimer = null;
    _overTimeDataTimer = null;
    _metricsDataTimer = null;
  }

  Future<bool> _refreshOnce() async {
    final selectedUrlBefore = _selectedServerAddress;
    final (statusOk, overtimeOk, metricsOk, _) = await (
      _fetchStatusData(),
      Future.delayed(
        const Duration(milliseconds: 100),
      ).then((_) => _fetchOverTimeData()),
      Future.delayed(
        const Duration(milliseconds: 100),
      ).then((_) => _fetchMetricsData()),
      Future.delayed(
        const Duration(milliseconds: 100),
      ).then((_) => _fetchSlowSystemData()),
    ).wait;

    if (_selectedServerAddress != selectedUrlBefore) return false;

    if (statusOk && overtimeOk && metricsOk) {
      _serverStatus = LoadStatus.loaded;
      notifyListeners();
      return true;
    }

    logger.w('Failed to fetch all status data.');
    _serverStatus = LoadStatus.error;
    notifyListeners();
    return false;
  }

  RealtimeStatusUseCase? _createRealtimeStatusUseCase() {
    if (_apiVersion == SupportedApiVersions.v6) {
      final metrics = _metricsRepository;
      final dns = _dnsRepository;
      if (metrics == null || dns == null) return null;
      return RealtimeStatusUseCaseV6(
        metricsRepository: metrics,
        dnsRepository: dns,
      );
    }

    final repo = _realtimeStatusRepository;
    if (repo == null) return null;
    return RealtimeStatusUseCaseV5(repository: repo);
  }

  Future<bool> _fetchStatusData() async {
    if (_selectedServerAddress == null) return false;
    final selectedUrlBefore = _selectedServerAddress;

    final useCase = _createRealtimeStatusUseCase();
    if (useCase == null) return false;

    final result = await useCase.fetchRealtimeStatus();

    if (_selectedServerAddress != selectedUrlBefore) return false;

    return result.fold(
      (status) {
        _realtimeStatus = status;
        _statusLoading = LoadStatus.loaded;
        _onUpdateServerStatus?.call(status.status == DnsBlockingStatus.enabled);
        notifyListeners();
        return true;
      },
      (error) {
        if (_handleFatalConnectionError(error, selectedUrlBefore)) return false;
        _recordConnectionFailure('Realtime status request', error);
        _statusLoading = LoadStatus.error;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> _fetchOverTimeData() async {
    if (_selectedServerAddress == null) return false;
    final selectedUrlBefore = _selectedServerAddress;
    final metricsRepo = _metricsRepository;
    if (metricsRepo == null) return false;

    final result = await metricsRepo.fetchOverTime();
    if (_selectedServerAddress != selectedUrlBefore) return false;

    return result.fold(
      (overTime) {
        _overtimeData = overTime;
        _overtimeDataLoading = LoadStatus.loaded;
        _statusLoading = LoadStatus.loaded;
        notifyListeners();
        return true;
      },
      (error) {
        _overtimeDataLoading = LoadStatus.error;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> _fetchMetricsData() async {
    if (_selectedServerAddress == null) return false;
    final selectedUrlBefore = _selectedServerAddress;
    final ftlRepo = _ftlRepository;
    if (ftlRepo == null) return false;

    final result = await ftlRepo.fetchInfoMetrics();
    if (_selectedServerAddress != selectedUrlBefore) return false;

    return result.fold(
      (metrics) {
        _ftlDnsMetrics = metrics;
        notifyListeners();
        return true;
      },
      (error) {
        if (error is NotSupportedException) return true;
        return false;
      },
    );
  }

  Future<bool> _fetchSlowSystemData() async {
    if (_selectedServerAddress == null) return false;
    final selectedUrlBefore = _selectedServerAddress;
    final ftlRepo = _ftlRepository;
    if (ftlRepo == null) return false;

    final (systemResult, sensorResult) = await (
      ftlRepo.fetchInfoSystem(),
      ftlRepo.fetchInfoSensors(),
    ).wait;
    if (_selectedServerAddress != selectedUrlBefore) return false;

    systemResult.fold((system) => _ftlSystem = system, (_) {});
    sensorResult.fold((sensor) => _ftlSensor = sensor, (_) {});
    notifyListeners();
    return true;
  }

  void _setupStatusDataTimer({bool runImmediately = true}) {
    Future<void> timerFn({Timer? timer}) async {
      if (_selectedServerAddress == null) {
        timer?.cancel();
        return;
      }
      final selectedUrlBefore = _selectedServerAddress;
      if (_isStatusFetchInProgress || _isConnecting) return;

      _isStatusFetchInProgress = true;
      final useCase = _createRealtimeStatusUseCase();
      if (useCase == null) {
        _isStatusFetchInProgress = false;
        return;
      }

      final prevBlockingStatus = _realtimeStatus?.status;
      final result = await useCase.fetchRealtimeStatus();
      _isStatusFetchInProgress = false;

      if (_selectedServerAddress != selectedUrlBefore) return;

      result.fold(
        (status) {
          _onUpdateServerStatus?.call(
            status.status == DnsBlockingStatus.enabled,
          );
          _realtimeStatus = status;
          _statusLoading = LoadStatus.loaded;
          if (_serverStatus != LoadStatus.loaded) {
            _serverStatus = LoadStatus.loaded;
          }
          notifyListeners();

          if (status.status != prevBlockingStatus &&
              _selectedServerAddress != null) {
            WidgetChannel.sendBlockingUpdated(
              serverAddress: _selectedServerAddress!,
            );
          }
        },
        (error) {
          if (_handleFatalConnectionError(error, selectedUrlBefore)) return;
          if (selectedUrlBefore == _selectedServerAddress) {
            var changed = false;
            if (_serverStatus == LoadStatus.loaded) {
              _recordConnectionFailure('Auto-refresh status request', error);
              logger.w(
                'Server disconnected: $error. '
                '$_selectedServerAlias ($_selectedServerAddress)',
              );
              _serverStatus = LoadStatus.error;
              changed = true;
            }
            if (_statusLoading == LoadStatus.loading) {
              _statusLoading = LoadStatus.error;
              changed = true;
            }
            if (changed) notifyListeners();
          }
        },
      );
    }

    if (runImmediately) timerFn();
    _statusDataTimer = Timer.periodic(
      Duration(milliseconds: (_autoRefreshTime ?? 5) * 1000 - 300),
      (timer) => timerFn(timer: timer),
    );
  }

  void _setupOverTimeDataTimer({
    bool runImmediately = true,
    bool isDelay = false,
  }) {
    Future<void> timerFn({Timer? timer}) async {
      if (_selectedServerAddress == null) {
        timer?.cancel();
        return;
      }
      if (_isOvertimeFetchInProgress || _isConnecting) return;
      final selectedUrlBefore = _selectedServerAddress;

      _isOvertimeFetchInProgress = true;
      final metricsRepo = _metricsRepository;
      if (metricsRepo == null) {
        _isOvertimeFetchInProgress = false;
        return;
      }

      if (isDelay) await const Duration(seconds: 1).delay;
      final (result, _) = await (
        metricsRepo.fetchOverTime(),
        _fetchSlowSystemData(),
      ).wait;
      _isOvertimeFetchInProgress = false;

      if (_selectedServerAddress != selectedUrlBefore) return;

      result.fold(
        (overTime) {
          _overtimeData = overTime;
          _overtimeDataLoading = LoadStatus.loaded;
          if (_serverStatus != LoadStatus.loaded) {
            _serverStatus = LoadStatus.loaded;
          }
          notifyListeners();
        },
        (error) {
          if (selectedUrlBefore == _selectedServerAddress) {
            var changed = false;
            if (_serverStatus == LoadStatus.loaded) {
              logger.w(
                'Server disconnected: $error. '
                '$_selectedServerAlias ($_selectedServerAddress)',
              );
              _serverStatus = LoadStatus.error;
              changed = true;
            }
            if (_overtimeDataLoading == LoadStatus.loading) {
              _overtimeDataLoading = LoadStatus.error;
              changed = true;
            }
            if (changed) notifyListeners();
          }
        },
      );
    }

    void start() {
      if (runImmediately) timerFn();
      _overTimeDataTimer = Timer.periodic(
        const Duration(minutes: 1),
        (timer) => timerFn(timer: timer),
      );
    }

    if (isDelay) {
      Future.delayed(const Duration(seconds: 2), start);
    } else {
      start();
    }
  }

  void _setupMetricsDataTimer({
    bool runImmediately = true,
    bool isDelay = false,
  }) {
    Future<void> timerFn({Timer? timer}) async {
      if (_selectedServerAddress == null) {
        timer?.cancel();
        return;
      }
      if (_isMetricsFetchInProgress || _isConnecting) return;
      final selectedUrlBefore = _selectedServerAddress;
      final ftlRepo = _ftlRepository;
      if (ftlRepo == null) return;

      _isMetricsFetchInProgress = true;
      if (isDelay) await const Duration(milliseconds: 500).delay;
      final result = await ftlRepo.fetchInfoMetrics();
      _isMetricsFetchInProgress = false;

      if (_selectedServerAddress != selectedUrlBefore) return;

      result.fold(
        (metrics) {
          _ftlDnsMetrics = metrics;
          notifyListeners();
        },
        (error) {
          if (error is NotSupportedException) return;
          logger.d('Metrics auto-refresh failed: $error');
        },
      );
    }

    void start() {
      if (runImmediately) timerFn();
      _metricsDataTimer = Timer.periodic(
        const Duration(minutes: 1),
        (timer) => timerFn(timer: timer),
      );
    }

    if (isDelay) {
      Future.delayed(const Duration(milliseconds: 700), start);
    } else {
      start();
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh(showLoadingIndicator: false);
    super.dispose();
  }
}
