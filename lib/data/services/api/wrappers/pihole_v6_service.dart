import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/utils/safe_dio_call.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:pi_hole_client/utils/logger.dart';
import 'package:pi_hole_client/utils/misc.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';
import 'package:result_dart/result_dart.dart';

/// Service wrapper around the OpenAPI-generated v6 API client.
///
/// Wraps all generated Dio-based API calls with [safeDioCall] to provide
/// consistent error handling via [Result<T>].
///
/// Authentication is handled via the [PiholeV6Api.setApiKey] method:
/// ```dart
/// api.setApiKey('x_header_sid', sid);
/// ```
///
/// Repositories depend on this service to access the Pi-hole v6 API.
/// Domain model mapping is handled in the repository layer.
class PiholeV6Service {
  PiholeV6Service({required PiholeV6Api api}) : _api = api;

  factory PiholeV6Service.fromConnection({
    required String url,
    bool allowUntrustedCert = true,
    bool ignoreCertificateErrors = false,
    String? pinnedCertificateSha256,
  }) {
    final normalizedUrl = url.replaceFirst(RegExp(r'/+$'), '');
    final dio = Dio(
      BaseOptions(
        baseUrl: '$normalizedUrl/api',
        connectTimeout: const Duration(milliseconds: 5000),
        receiveTimeout: const Duration(milliseconds: 3000),
      ),
    );
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => createHttpClient(
        allowUntrustedCert: allowUntrustedCert,
        ignoreCertificateErrors: ignoreCertificateErrors,
        pinnedCertificateSha256: pinnedCertificateSha256,
      ),
    );

    return PiholeV6Service(api: PiholeV6Api(dio: dio));
  }

  final PiholeV6Api _api;

  void setSid(String sid) {
    _api.setApiKey('x_header_sid', sid);
  }

  // Lazy API instances
  late final _authApi = _api.getAuthenticationApi();
  late final _actionsApi = _api.getActionsApi();
  late final _clientApi = _api.getClientManagementApi();
  late final _dhcpApi = _api.getDHCPApi();
  late final _dnsApi = _api.getDNSControlApi();
  late final _domainApi = _api.getDomainManagementApi();
  late final _ftlApi = _api.getFTLInformationApi();
  late final _groupApi = _api.getGroupManagementApi();
  late final _listApi = _api.getListManagementApi();
  late final _metricsApi = _api.getMetricsApi();
  late final _networkApi = _api.getNetworkInformationApi();
  late final _configApi = _api.getPiHoleConfigurationApi();

  // ===========================================================================
  // Authentication
  // ===========================================================================

  /// Creates a new Pi-hole v6 session through the generated auth API.
  ///
  /// FTL v6.7 documents TOTP support for `POST /auth`, but its OpenAPI
  /// `password` schema omits the `totp` property. To keep generated transport
  /// without forking the pinned upstream spec, this request uses an isolated
  /// Dio clone and injects the optional TOTP value after generated
  /// serialization. The shared SID interceptor is removed from the clone, so
  /// login stays unauthenticated without mutating concurrent requests.
  Future<Result<GetAuth200Response>> postAuth({
    required String password,
    int? totp,
  }) async {
    try {
      final dio = _api.dio.clone();
      dio.interceptors.removeWhere((i) => i is ApiKeyAuthInterceptor);
      if (totp != null) {
        dio.interceptors.insert(0, _TotpAuthRequestInterceptor(totp));
      }

      final response = await AuthenticationApi(dio).addAuth(
        password: Password(password: password),
      );
      return Success(response.requireData);
    } on DioException catch (e) {
      final totpError = _parseTotpError(e);
      if (totpError != null) {
        return Failure(totpError);
      }
      final exception = ApiException.fromDioException(e);
      logger.e('Dio auth error: ${exception.message}');
      return Failure(exception);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<Result<GetAuth200Response>> getAuth() {
    return safeDioCall(() async {
      final response = await _authApi.getAuth();
      return response.requireData;
    });
  }

  /// Reads auth capabilities without attaching the shared SID.
  ///
  /// A cloned Dio instance keeps the connection adapter and non-auth
  /// interceptors while removing the generated API-key interceptor only from
  /// this request path. The shared generated client remains untouched, so an
  /// unauthenticated probe cannot race with concurrent authenticated calls.
  Future<Result<GetAuth200Response>> getAuthUnauthenticated() {
    return safeDioCall(() async {
      final dio = _api.dio.clone();
      dio.interceptors.removeWhere((i) => i is ApiKeyAuthInterceptor);
      final response = await AuthenticationApi(dio).getAuth();
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteAuth() {
    return safeDioCall(() async {
      await _authApi.deleteGroups();
      return unit;
    });
  }

  Future<Result<GetAuthSessions200Response>> getAuthSessions() {
    return safeDioCall(() async {
      final response = await _authApi.getAuthSessions();
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteAuthSession({required int id}) {
    return safeDioCall(() async {
      await _authApi.deleteAuthSession(id: id);
      return unit;
    });
  }

  // ===========================================================================
  // Metrics
  // ===========================================================================

  Future<Result<GetActivityMetrics200Response>> getHistory() {
    return safeDioCall(() async {
      final response = await _metricsApi.getActivityMetrics();
      return response.requireData;
    });
  }

  Future<Result<GetClientMetrics200Response>> getHistoryClients({
    int? count = 10,
  }) {
    return safeDioCall(() async {
      final response = await _metricsApi.getClientMetrics(N: count);
      return response.requireData;
    });
  }

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
    bool? dnssec,
    bool? disk,
  }) {
    return safeDioCall(() async {
      final response = await _metricsApi.getQueries(
        from: from,
        until: until,
        length: length,
        start: start,
        cursor: cursor,
        domain: domain,
        clientIp: clientIp,
        clientName: clientName,
        upstream: upstream,
        type: type,
        status: status,
        reply: reply,
        dnssec: dnssec,
        disk: disk,
      );
      return response.requireData;
    });
  }

  Future<Result<GetMetricsSummary200Response>> getStatsSummary() {
    return safeDioCall(() async {
      final response = await _metricsApi.getMetricsSummary();
      return response.requireData;
    });
  }

  Future<Result<GetMetricsUpstreams200Response>> getStatsUpstreams() {
    return safeDioCall(() async {
      final response = await _metricsApi.getMetricsUpstreams();
      return response.requireData;
    });
  }

  Future<Result<GetMetricsTopDomains200Response>> getStatsTopDomains({
    bool? blocked,
    int? count,
  }) {
    return safeDioCall(() async {
      final response = await _metricsApi.getMetricsTopDomains(
        blocked: blocked,
        count: count,
      );
      return response.requireData;
    });
  }

  Future<Result<GetMetricsTopClients200Response>> getStatsTopClients({
    bool? blocked,
    int? count,
  }) {
    return safeDioCall(() async {
      final response = await _metricsApi.getMetricsTopClients(
        blocked: blocked,
        count: count,
      );
      return response.requireData;
    });
  }

  // ===========================================================================
  // Groups
  // ===========================================================================

  Future<Result<GetGroups200Response>> getGroups() {
    return safeDioCall(() async {
      final response = await _groupApi.getGroups();
      return response.requireData;
    });
  }

  Future<Result<GetGroups200Response>> addGroup({
    required String name,
    String? comment,
    bool? enabled,
  }) {
    return safeDioCall(() async {
      final response = await _groupApi.addGroup(
        body: GroupsPost(name: name, comment: comment, enabled: enabled),
      );
      return response.requireData;
    });
  }

  Future<Result<GetGroups200Response>> updateGroup({
    required String name,
    String? comment,
    bool? enabled,
  }) {
    return safeDioCall(() async {
      final response = await _groupApi.replaceGroup(
        name: name,
        body: GroupsPut(name: name, comment: comment, enabled: enabled),
      );
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteGroup({required String name}) {
    return safeDioCall(() async {
      await _groupApi.deleteGroups(name: name);
      return unit;
    });
  }

  // ===========================================================================
  // Domains
  // ===========================================================================

  Future<Result<GetDomains200Response>> getDomains() {
    return safeDioCall(() async {
      final response = await _domainApi.getDomains();
      return response.requireData;
    });
  }

  Future<Result<GetDomains200Response>> addDomain({
    required String domain,
    required String type,
    String? comment,
    List<int>? groups,
    bool? enabled,
  }) {
    return safeDioCall(() async {
      final response = await _domainApi.addDomain(
        type: type,
        kind: 'exact',
        domain: domain,
        body: Post(
          domain: domain,
          type: type,
          kind: 'exact',
          comment: comment,
          groups: groups,
          enabled: enabled,
        ),
      );
      return response.requireData;
    });
  }

  Future<Result<GetDomains200Response>> updateDomain({
    required String domain,
    required String type,
    String? comment,
    List<int>? groups,
    bool? enabled,
  }) {
    return safeDioCall(() async {
      final response = await _domainApi.replaceDomain(
        type: type,
        kind: 'exact',
        domain: domain,
        body: ReplaceDomainRequest(
          domain: domain,
          type: type,
          kind: 'exact',
          comment: comment,
          groups: groups,
          enabled: enabled,
        ),
      );
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteDomain({
    required String domain,
    required String type,
  }) {
    return safeDioCall(() async {
      await _domainApi.deleteDomain(type: type, kind: 'exact', domain: domain);
      return unit;
    });
  }

  // ===========================================================================
  // Lists
  // ===========================================================================

  Future<Result<GetLists200Response>> getLists() {
    return safeDioCall(() async {
      final response = await _listApi.getLists();
      return response.requireData;
    });
  }

  Future<Result<GetLists200Response>> addList({
    required String address,
    required String type,
    String? comment,
    List<int>? groups,
    bool? enabled,
  }) {
    return safeDioCall(() async {
      final response = await _listApi.addList(
        body: ListsPost(
          address: address,
          type: type,
          comment: comment,
          groups: groups,
          enabled: enabled,
        ),
      );
      return response.requireData;
    });
  }

  Future<Result<GetLists200Response>> updateList({
    required String address,
    required String type,
    String? comment,
    List<int>? groups,
    bool? enabled,
  }) {
    return safeDioCall(() async {
      final response = await _listApi.replaceLists(
        list: address,
        type: type,
        body: ListsPut(
          address: address,
          type: type,
          comment: comment,
          groups: groups,
          enabled: enabled,
        ),
      );
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteList({
    required String address,
    required String type,
  }) {
    return safeDioCall(() async {
      await _listApi.deleteLists(list: address, type: type);
      return unit;
    });
  }

  Future<Result<GetSearch200Response>> searchList({
    required String domain,
    bool? partial,
  }) {
    return safeDioCall(() async {
      final response = await _listApi.getSearch(domain: domain, partial: partial);
      return response.requireData;
    });
  }

  // ===========================================================================
  // Client management
  // ===========================================================================

  Future<Result<GetClients200Response>> getClients() {
    return safeDioCall(() async {
      final response = await _clientApi.getClients();
      return response.requireData;
    });
  }

  Future<Result<GetClients200Response>> addClient({
    required String client,
    String? comment,
    List<int>? groups,
  }) {
    return safeDioCall(() async {
      final response = await _clientApi.addClient(
        body: AddClientRequest(
          client: client,
          comment: comment,
          groups: groups,
        ),
      );
      return response.requireData;
    });
  }

  Future<Result<ReplaceClient200Response>> updateClient({
    required String client,
    String? comment,
    List<int>? groups,
  }) {
    return safeDioCall(() async {
      final response = await _clientApi.replaceClient(
        client: client,
        body: ReplaceClientRequest(
          client: client,
          comment: comment,
          groups: groups,
        ),
      );
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteClient({required String client}) {
    return safeDioCall(() async {
      await _clientApi.deleteClient(client: client);
      return unit;
    });
  }

  // ===========================================================================
  // DNS control
  // ===========================================================================

  Future<Result<GetBlocking200Response>> getBlocking() {
    return safeDioCall(() async {
      final response = await _dnsApi.getBlocking();
      return response.requireData;
    });
  }

  Future<Result<GetBlocking200Response>> setBlocking({
    required bool blocking,
    int? timer,
  }) {
    return safeDioCall(() async {
      final response = await _dnsApi.setBlocking(
        blocking: blocking,
        timer: timer,
      );
      return response.requireData;
    });
  }

  // ===========================================================================
  // Actions
  // ===========================================================================

  Future<Result<Unit>> actionFlushNetwork() {
    return safeDioCall(() async {
      await _actionsApi.actionFlushNetwork();
      return unit;
    });
  }

  Future<Result<Unit>> actionFlushArp() {
    return safeDioCall(() async {
      await _actionsApi.actionFlushArp();
      return unit;
    });
  }

  Future<Result<Unit>> actionFlushLogs() {
    return safeDioCall(() async {
      await _actionsApi.actionFlushLogs();
      return unit;
    });
  }

  Future<Result<Unit>> actionRestartDns() {
    return safeDioCall(() async {
      await _actionsApi.actionRestartDns();
      return unit;
    });
  }

  // ===========================================================================
  // FTL information
  // ===========================================================================

  Future<Result<GetFtlinfo200Response>> getFtlInfo() {
    return safeDioCall(() async {
      final response = await _ftlApi.getFtlInfo();
      return response.requireData;
    });
  }

  // ===========================================================================
  // Network information
  // ===========================================================================

  Future<Result<GetNetwork200Response>> getNetworkDevices({
    int? maxDevices,
    int? maxAddresses,
  }) {
    return safeDioCall(() async {
      final response = await _networkApi.getNetwork(
        maxDevices: maxDevices,
        maxAddresses: maxAddresses,
      );
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteNetworkDevice({required int id}) {
    return safeDioCall(() async {
      await _networkApi.deleteNetworkDevice(id: id);
      return unit;
    });
  }

  // ===========================================================================
  // Pi-hole configuration
  // ===========================================================================

  Future<Result<GetConfig200Response>> getConfig() {
    return safeDioCall(() async {
      final response = await _configApi.getConfig();
      return response.requireData;
    });
  }

  Future<Result<GetConfig200Response>> patchConfig({
    required ConfigConfig config,
  }) {
    return safeDioCall(() async {
      final response = await _configApi.patchConfig(config: config);
      return response.requireData;
    });
  }

  Future<Result<Unit>> addConfigArrayItem({
    required String element,
    required String value,
    bool? restart,
  }) {
    return safeDioCall(() async {
      await _configApi.addArrayItem(
        element: element,
        value: value,
        restart: restart,
      );
      return unit;
    });
  }

  Future<Result<Unit>> deleteConfigArrayItem({
    required String element,
    required String value,
    bool? restart,
  }) {
    return safeDioCall(() async {
      await _configApi.deleteArrayItem(
        element: element,
        value: value,
        restart: restart,
      );
      return unit;
    });
  }

  // ===========================================================================
  // DHCP
  // ===========================================================================

  Future<Result<GetDhcp200Response>> getDhcpLeases() {
    return safeDioCall(() async {
      final response = await _dhcpApi.getDhcp();
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteDhcpLease({required String ip}) {
    return safeDioCall(() async {
      await _dhcpApi.deleteDhcp(ip: ip);
      return unit;
    });
  }
}

class _TotpAuthRequestInterceptor extends Interceptor {
  _TotpAuthRequestInterceptor(this.totp);

  final int totp;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'POST' && options.path == '/auth') {
      final data = options.data;
      Map<String, dynamic>? body;

      if (data is String) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          body = Map<String, dynamic>.from(decoded);
        }
      } else if (data is Map<String, dynamic>) {
        body = Map<String, dynamic>.from(data);
      }

      if (body != null) {
        body['totp'] = totp;
        options.data = jsonEncode(body);
      }
    }
    handler.next(options);
  }
}

Exception? _parseTotpError(DioException error) {
  final statusCode = error.response?.statusCode;
  if (statusCode != 400 && statusCode != 401 && statusCode != 429) {
    return null;
  }

  dynamic data = error.response?.data;
  if (data is String) {
    try {
      data = jsonDecode(data);
    } catch (_) {
      return null;
    }
  }
  if (data is! Map) return null;

  final errorBody = data['error'];
  if (errorBody is! Map) return null;

  final key = errorBody['key']?.toString();
  final message = errorBody['message']?.toString() ?? '';
  if (!message.contains('2FA token')) return null;

  if (statusCode == 400 &&
      key == 'bad_request' &&
      message.contains('No 2FA token found in JSON payload')) {
    return TotpRequiredException(message);
  }
  if (statusCode == 401 && key == 'unauthorized') {
    if (message.contains('Reused 2FA token')) {
      return TotpReusedException(message);
    }
    if (message.contains('Invalid 2FA token')) {
      return TotpInvalidException(message);
    }
  }
  if (statusCode == 429 && key == 'rate_limiting') {
    return TotpRateLimitException(message);
  }
  return null;
}
