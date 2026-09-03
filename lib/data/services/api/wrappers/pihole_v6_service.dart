import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:pi_hole_client/data/services/api/utils/safe_dio_call.dart';
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

  Future<Result<GetAuth200Response>> postAuth({required String password}) {
    return safeDioCall(() async {
      final response = await _authApi.addAuth(
        password: Password(password: password),
      );
      return response.requireData;
    });
  }

  Future<Result<GetAuth200Response>> getAuth() {
    return safeDioCall(() async {
      final response = await _authApi.getAuth();
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
    int? cursor,
    String? domain,
    String? clientIp,
    String? clientName,
    String? upstream,
    String? type,
    String? status,
  }) {
    return safeDioCall(() async {
      final response = await _metricsApi.getQueries(
        from: from,
        until: until,
        length: length,
        cursor: cursor,
        domain: domain,
        clientIp: clientIp,
        clientName: clientName,
        upstream: upstream,
        type: type,
        status: status,
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

  Future<Result<GetMetricsQueryTypes200Response>> getQueryTypes() {
    return safeDioCall(() async {
      final response = await _metricsApi.getMetricsQueryTypes();
      return response.requireData;
    });
  }

  // ===========================================================================
  // DNS Control
  // ===========================================================================

  Future<Result<GetBlocking200Response>> getDnsBlocking() {
    return safeDioCall(() async {
      final response = await _dnsApi.getBlocking();
      return response.requireData;
    });
  }

  Future<Result<GetBlocking200Response>> setDnsBlocking({
    SetBlockingRequest? request,
  }) {
    return safeDioCall(() async {
      final response = await _dnsApi.setBlocking(setBlockingRequest: request);
      return response.requireData;
    });
  }

  // ===========================================================================
  // Groups
  // ===========================================================================

  Future<Result<GetGroups200Response>> getAllGroups() {
    return safeDioCall(() async {
      final response = await _groupApi.getAllGroups();
      return response.requireData;
    });
  }

  Future<Result<GetGroups200Response>> getGroups({required String name}) {
    return safeDioCall(() async {
      final response = await _groupApi.getGroups(name: name);
      return response.requireData;
    });
  }

  Future<Result<ReplaceGroup200Response>> addGroup({GroupsPost? body}) {
    return safeDioCall(() async {
      final response = await _groupApi.addGroup(groupsPost: body);
      return response.requireData;
    });
  }

  Future<Result<ReplaceGroup200Response>> replaceGroup({
    required String name,
    GroupsPut? body,
  }) {
    return safeDioCall(() async {
      final response = await _groupApi.replaceGroup(
        name: name,
        groupsPut: body,
      );
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteGroup({required String name}) {
    return safeDioCall(() async {
      await _groupApi.deleteGroup(name: name);
      return unit;
    });
  }

  // ===========================================================================
  // Domains
  // ===========================================================================

  Future<Result<GetDomains200Response>> getDomains({
    required String type,
    required String kind,
  }) {
    return safeDioCall(() async {
      final response = await _domainApi.getDomains(type: type, kind: kind);
      return response.requireData;
    });
  }

  Future<Result<GetDomains200Response>> getDomain({
    required String type,
    required String kind,
    required String domain,
  }) {
    return safeDioCall(() async {
      final response = await _domainApi.getDomain(
        type: type,
        kind: kind,
        domain: domain,
      );
      return response.requireData;
    });
  }

  Future<Result<DomainsPut200Response>> addDomain({
    required String type,
    required String kind,
    required String domain,
    DomainsPost? body,
  }) {
    return safeDioCall(() async {
      final response = await _domainApi.addDomain(
        type: type,
        kind: kind,
        domain: domain,
        domainsPost: body,
      );
      return response.requireData;
    });
  }

  Future<Result<DomainsPut200Response>> replaceDomain({
    required String type,
    required String kind,
    required String domain,
    DomainsPut? body,
  }) {
    return safeDioCall(() async {
      final response = await _domainApi.replaceDomain(
        type: type,
        kind: kind,
        domain: domain,
        domainsPut: body,
      );
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteDomain({
    required String type,
    required String kind,
    required String domain,
  }) {
    return safeDioCall(() async {
      await _domainApi.deleteDomain(type: type, kind: kind, domain: domain);
      return unit;
    });
  }

  // ===========================================================================
  // Clients
  // ===========================================================================

  Future<Result<GetClients200Response>> getClients() {
    return safeDioCall(() async {
      final response = await _clientApi.getClients();
      return response.requireData;
    });
  }

  Future<Result<GetClients200Response>> getClient({required String client}) {
    return safeDioCall(() async {
      final response = await _clientApi.getClient(client: client);
      return response.requireData;
    });
  }

  Future<Result<ClientsPut200Response>> addClient({
    required String client,
    ClientsPost? body,
  }) {
    return safeDioCall(() async {
      final response = await _clientApi.addClient(
        client: client,
        clientsPost: body,
      );
      return response.requireData;
    });
  }

  Future<Result<ClientsPut200Response>> replaceClient({
    required String client,
    ClientsPut? body,
  }) {
    return safeDioCall(() async {
      final response = await _clientApi.replaceClient(
        client: client,
        clientsPut: body,
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
  // DHCP
  // ===========================================================================

  Future<Result<GetDhcpLeases200Response>> getDhcpLeases() {
    return safeDioCall(() async {
      final response = await _dhcpApi.getDhcpLeases();
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteDhcpLease({required String ip}) {
    return safeDioCall(() async {
      await _dhcpApi.deleteDhcpLease(ip: ip);
      return unit;
    });
  }

  // ===========================================================================
  // Lists
  // ===========================================================================

  Future<Result<GetLists200Response>> getLists({
    required String list,
    String? type,
  }) {
    return safeDioCall(() async {
      final response = await _listApi.getLists(list: list, type: type);
      return response.requireData;
    });
  }

  Future<Result<ListsPut200Response>> addList({
    required String list,
    ListsPost? body,
  }) {
    return safeDioCall(() async {
      final response = await _listApi.addList(list: list, listsPost: body);
      return response.requireData;
    });
  }

  Future<Result<ListsPut200Response>> replaceList({
    required String list,
    ListsPut? body,
  }) {
    return safeDioCall(() async {
      final response = await _listApi.replaceList(list: list, listsPut: body);
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteList({required String list}) {
    return safeDioCall(() async {
      await _listApi.deleteList(list: list);
      return unit;
    });
  }

  // ===========================================================================
  // FTL Info
  // ===========================================================================

  Future<Result<GetInfoFtl200Response>> getFtlInfo() {
    return safeDioCall(() async {
      final response = await _ftlApi.getInfoFtl();
      return response.requireData;
    });
  }

  Future<Result<GetInfoSystem200Response>> getSystemInfo() {
    return safeDioCall(() async {
      final response = await _ftlApi.getInfoSystem();
      return response.requireData;
    });
  }

  Future<Result<GetInfoHost200Response>> getHostInfo() {
    return safeDioCall(() async {
      final response = await _ftlApi.getInfoHost();
      return response.requireData;
    });
  }

  Future<Result<GetInfoMessages200Response>> getMessages() {
    return safeDioCall(() async {
      final response = await _ftlApi.getInfoMessages();
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteMessage({required int messageId}) {
    return safeDioCall(() async {
      await _ftlApi.deleteMessage(messageId: messageId);
      return unit;
    });
  }

  // ===========================================================================
  // Network Info
  // ===========================================================================

  Future<Result<GetGateway200Response>> getGateway() {
    return safeDioCall(() async {
      final response = await _networkApi.getGateway();
      return response.requireData;
    });
  }

  Future<Result<GetDevices200Response>> getNetworkDevices({
    int? maxDevices = 100,
    int? maxAddresses = 3,
  }) {
    return safeDioCall(() async {
      final response = await _networkApi.getDevices(
        maxDevices: maxDevices,
        maxAddresses: maxAddresses,
      );
      return response.requireData;
    });
  }

  Future<Result<Unit>> deleteNetworkDevice({required int deviceId}) {
    return safeDioCall(() async {
      await _networkApi.deleteDevice(deviceId: deviceId);
      return unit;
    });
  }

  // ===========================================================================
  // Config
  // ===========================================================================

  Future<Result<GetConfig200Response>> getConfig({String? element}) {
    return safeDioCall(() async {
      final response = await _configApi.getConfig(element: element);
      return response.requireData;
    });
  }

  Future<Result<PatchConfig200Response>> patchConfig({
    String? element,
    Config? config,
  }) {
    return safeDioCall(() async {
      final response = await _configApi.patchConfig(
        element: element,
        config: config,
      );
      return response.requireData;
    });
  }
}
