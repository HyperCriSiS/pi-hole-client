import 'dart:async';

import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/domain/model/metrics/queries.dart';
import 'package:pi_hole_client/domain/services/logs_pagination_service.dart';
import 'package:pi_hole_client/utils/logger.dart';

/// A service for fetching live log differences in a specific time window.
///
/// This service uses a [LogsPaginationService] to load logs
/// incrementally from the last known end time to the current time.
class LiveLogsService {
  LiveLogsService({
    required LogsPaginationService paginationService,
    required DateTime endTime,
    Duration requestTimeout = const Duration(seconds: 15),
  }) : _paginationService = paginationService,
       _lastEnd = endTime,
       _requestTimeout = requestTimeout;

  final LogsPaginationService _paginationService;
  final Duration _requestTimeout;

  DateTime _lastEnd;

  bool _liveLoading = false;

  /// Whether a [tickOnce] call is currently in progress.
  bool get isLoading => _liveLoading;

  /// The end timestamp of the most recent successful tick (used as the start
  /// of the next).
  DateTime? get lastEnd => _lastEnd;

  /// Fetches a new batch of live logs since the last successful tick.
  ///
  /// Each pagination request is guarded by [_requestTimeout]. Without this
  /// watchdog, a network request that never completes leaves [_liveLoading]
  /// set forever and all subsequent live-log ticks are ignored until the app
  /// is restarted.
  ///
  /// The time window advances only after a successful tick. On timeout/error,
  /// [_lastEnd] is intentionally kept unchanged so the next tick retries the
  /// same window instead of silently dropping queries.
  Future<List<Log>> tickOnce() async {
    logger.d('Ticking live logs');
    if (_liveLoading) return const [];

    _liveLoading = true;
    try {
      const maxPagesPerTick = 10;
      final end = DateTime.now();
      final start = _lastEnd;

      _paginationService.reset(start, end);

      final collected = <Log>[];
      for (var i = 0; i < maxPagesPerTick; i++) {
        final page = await _paginationService
            .loadNextPage()
            .timeout(_requestTimeout);
        if (page.isEmpty) break;
        collected.addAll(page);
        if (_paginationService.finished != LoadStatus.loading) break;

        if (i == maxPagesPerTick - 1) {
          logger.w(
            'Live logs tick reached max page limit ($maxPagesPerTick), '
            'there might be more logs.',
          );
        }
      }

      _lastEnd = end;
      logger.d('Live tick ${collected.length} logs, window: $start -> $end');
      return collected;
    } on TimeoutException catch (e, s) {
      logger.w(
        'Live tick timed out after ${_requestTimeout.inSeconds}s. '
        'Keeping the previous cursor so the next tick can retry. Error: $e\n$s',
      );
      return const [];
    } catch (e, s) {
      logger.e('Live tick error: $e\n$s');
      return const [];
    } finally {
      _liveLoading = false;
    }
  }
}
