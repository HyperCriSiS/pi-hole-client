import 'package:flutter/foundation.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/repository_bundle.dart';
import 'package:pi_hole_client/domain/model/server/api_versions.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';

typedef ServerOverviewReader = Future<ServerOverviewMetrics> Function(Server);

class ServerOverviewMetrics {
  const ServerOverviewMetrics({required this.queries, required this.blocked, required this.blockedPercentage});
  final int queries;
  final int blocked;
  final double blockedPercentage;
}

enum ServerOverviewLoadState { notRequested, loading, loaded, failed }

class ServerOverviewEntry {
  const ServerOverviewEntry({this.state = ServerOverviewLoadState.notRequested, this.metrics, this.updatedAt});
  final ServerOverviewLoadState state;
  final ServerOverviewMetrics? metrics;
  final DateTime? updatedAt;
}

/// User-initiated, sequential reads. No timer, server switching or write API.
class MultiServerOverviewController extends ChangeNotifier {
  MultiServerOverviewController({required List<Server> servers, required ServerOverviewReader reader})
      : servers = List.unmodifiable(servers), _reader = reader;
  final List<Server> servers;
  final ServerOverviewReader _reader;
  final Map<String, ServerOverviewEntry> _entries = {};
  bool _busy = false;
  bool _disposed = false;

  bool get busy => _busy;
  ServerOverviewEntry entryFor(Server server) => _entries[server.address] ?? const ServerOverviewEntry();

  Future<void> refreshAll() async {
    if (_busy || _disposed) return;
    _busy = true;
    notifyListeners();
    try {
      for (final server in servers) {
        if (_disposed) break;
        await _readOne(server);
      }
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> refreshOne(Server server) async {
    if (_busy || _disposed || !servers.contains(server)) return;
    _busy = true;
    notifyListeners();
    try {
      await _readOne(server);
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _readOne(Server server) async {
    _entries[server.address] = const ServerOverviewEntry(state: ServerOverviewLoadState.loading);
    if (!_disposed) notifyListeners();
    try {
      final metrics = await _reader(server);
      if (_disposed) return;
      _entries[server.address] = ServerOverviewEntry(
        state: ServerOverviewLoadState.loaded, metrics: metrics, updatedAt: DateTime.now(),
      );
    } catch (_) {
      // Do not expose authentication errors, SIDs or raw response content in UI.
      if (_disposed) return;
      _entries[server.address] = const ServerOverviewEntry(state: ServerOverviewLoadState.failed);
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Reuses the selected bundle when possible, so it cannot be rebound during
/// an overview request. Other servers use isolated, existing repository APIs.
/// Pi-hole v5 provides Summary via Realtime; v6 via stats/summary.
Future<ServerOverviewMetrics> readServerOverview(
  Server server, {
  required CreateRepositoryBundle createBundle,
  RepositoryBundle? selectedBundle,
}) async {
  final reuse = selectedBundle != null &&
      selectedBundle.serverAddress == server.address &&
      selectedBundle.apiVersion == server.apiVersion &&
      selectedBundle.allowUntrustedCert == server.allowUntrustedCert &&
      selectedBundle.ignoreCertificateErrors == server.ignoreCertificateErrors &&
      selectedBundle.pinnedCertificateSha256 == server.pinnedCertificateSha256;
  final bundle = reuse ? selectedBundle : createBundle(server: server);
  switch (server.apiVersion) {
    case SupportedApiVersions.v5:
      final value = (await bundle.realtimeStatus.fetchRealtimeStatus()).getOrThrow().summary;
      return ServerOverviewMetrics(
        queries: value.dnsQueriesToday,
        blocked: value.adsBlockedToday,
        blockedPercentage: value.adsPercentageToday,
      );
    case SupportedApiVersions.v6:
      final value = (await bundle.metrics.fetchStatsSummary()).getOrThrow();
      return ServerOverviewMetrics(
        queries: value.dnsQueriesToday,
        blocked: value.adsBlockedToday,
        blockedPercentage: value.adsPercentageToday,
      );
    default:
      throw StateError('Unsupported API version');
  }
}
