import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/pihole_v6_api_client.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/data/services/local/session_credential_service.dart';
import 'package:pi_hole_client/domain/services/app_log_service.dart';

/// Keeps one [V6SessionCache] per server address, shared across every
/// `RepositoryBundle` built for that address.
class V6SessionCacheStore {
  V6SessionCacheStore({AppLogService? appLogService})
    : _appLogService = appLogService;

  final AppLogService? _appLogService;
  final Map<String, V6SessionCache> _caches = {};

  /// Returns the cache for [address], creating it on first use. An existing
  /// cache is rebound to freshly built dependencies (its live session state is
  /// preserved) and returned.
  V6SessionCache getOrCreate({
    required String address,
    required SessionCredentialService creds,
    PiholeV6ApiClient? client,
    PiholeV6Service? service,
  }) {
    assert(client != null || service != null);
    final existing = _caches[address];
    if (existing != null) {
      existing.rebind(creds: creds, client: client, service: service);
      return existing;
    }
    final cache = V6SessionCache(
      creds: creds,
      client: client,
      service: service,
      appLogService: _appLogService,
    );
    _caches[address] = cache;
    return cache;
  }

  /// Drops the cache for [address].
  void remove(String address) => _caches.remove(address);

  /// Drops every cache.
  void clear() => _caches.clear();
}
