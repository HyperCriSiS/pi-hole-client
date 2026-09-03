import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';
import 'package:result_dart/result_dart.dart';

import 'mocks.mocks.dart';

// Test data
final _testSession = SessionSession(
  valid: true,
  totp: false,
  sid: 'test-sid',
  validity: 300,
  message: 'correct password',
);

// Helper to build a Dio Response<T>.
Response<T> dioResponse<T>(T data, {int statusCode = 200}) {
  return Response(
    data: data,
    statusCode: statusCode,
    requestOptions: RequestOptions(),
  );
}

// Helper to build a DioException with Pi-hole error body.
DioException dioError({
  int statusCode = 401,
  String key = 'unauthorized',
  String message = 'Unauthorized',
}) {
  return DioException(
    requestOptions: RequestOptions(),
    response: Response(
      statusCode: statusCode,
      data: {
        'error': {'key': key, 'message': message},
      },
      requestOptions: RequestOptions(),
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  late PiholeV6Service service;
  late MockPiholeV6Api mockApi;
  late MockAuthenticationApi mockAuthApi;
  late MockActionsApi mockActionsApi;
  late MockClientManagementApi mockClientApi;
  late MockDHCPApi mockDhcpApi;
  late MockDNSControlApi mockDnsApi;
  late MockDomainManagementApi mockDomainApi;
  late MockFTLInformationApi mockFtlApi;
  late MockGroupManagementApi mockGroupApi;
  late MockListManagementApi mockListApi;
  late MockMetricsApi mockMetricsApi;
  late MockNetworkInformationApi mockNetworkApi;
  late MockPiHoleConfigurationApi mockConfigApi;

  setUp(() {
    mockApi = MockPiholeV6Api();
    mockAuthApi = MockAuthenticationApi();
    mockActionsApi = MockActionsApi();
    mockClientApi = MockClientManagementApi();
    mockDhcpApi = MockDHCPApi();
    mockDnsApi = MockDNSControlApi();
    mockDomainApi = MockDomainManagementApi();
    mockFtlApi = MockFTLInformationApi();
    mockGroupApi = MockGroupManagementApi();
    mockListApi = MockListManagementApi();
    mockMetricsApi = MockMetricsApi();
    mockNetworkApi = MockNetworkInformationApi();
    mockConfigApi = MockPiHoleConfigurationApi();

    when(mockApi.getAuthenticationApi()).thenReturn(mockAuthApi);
    when(mockApi.getActionsApi()).thenReturn(mockActionsApi);
    when(mockApi.getClientManagementApi()).thenReturn(mockClientApi);
    when(mockApi.getDHCPApi()).thenReturn(mockDhcpApi);
    when(mockApi.getDNSControlApi()).thenReturn(mockDnsApi);
    when(mockApi.getDomainManagementApi()).thenReturn(mockDomainApi);
    when(mockApi.getFTLInformationApi()).thenReturn(mockFtlApi);
    when(mockApi.getGroupManagementApi()).thenReturn(mockGroupApi);
    when(mockApi.getListManagementApi()).thenReturn(mockListApi);
    when(mockApi.getMetricsApi()).thenReturn(mockMetricsApi);
    when(mockApi.getNetworkInformationApi()).thenReturn(mockNetworkApi);
    when(mockApi.getPiHoleConfigurationApi()).thenReturn(mockConfigApi);

    service = PiholeV6Service(api: mockApi);
  });

  test('setSid configures the generated x_header_sid API key', () {
    service.setSid('sid-123');

    verify(mockApi.setApiKey('x_header_sid', 'sid-123')).called(1);
  });

  // ==========================================================================
  // Authentication
  // ==========================================================================
  group('Authentication', () {
    group('postAuth', () {
      test('returns Success with response data', () async {
        final mockResponse = GetAuth200Response(session: _testSession);
        when(
          mockAuthApi.addAuth(password: anyNamed('password')),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.postAuth(password: 'test123');

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), mockResponse);
        verify(mockAuthApi.addAuth(password: anyNamed('password'))).called(1);
      });

      test('returns Failure on DioException', () async {
        when(
          mockAuthApi.addAuth(password: anyNamed('password')),
        ).thenThrow(dioError(message: 'password incorrect'));

        final result = await service.postAuth(password: 'wrong');

        expect(result.isError(), true);
        final error = result.exceptionOrNull()! as ApiException;
        expect(error.message, 'password incorrect');
      });
    });

    group('getAuth', () {
      test('returns Success with session data', () async {
        final mockResponse = GetAuth200Response(session: _testSession);
        when(
          mockAuthApi.getAuth(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getAuth();

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), mockResponse);
      });

      test('returns Failure on DioException', () async {
        when(mockAuthApi.getAuth()).thenThrow(dioError());

        final result = await service.getAuth();

        expect(result.isError(), true);
      });
    });

    group('deleteAuth', () {
      test('returns Success with Unit', () async {
        when(
          mockAuthApi.deleteGroups(),
        ).thenAnswer((_) async => dioResponse<void>(null, statusCode: 204));

        final result = await service.deleteAuth();

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), unit);
      });
    });

    group('getAuthSessions', () {
      test('returns Success with sessions data', () async {
        final mockResponse = GetAuthSessions200Response();
        when(
          mockAuthApi.getAuthSessions(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getAuthSessions();

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), mockResponse);
      });
    });

    group('deleteAuthSession', () {
      test('returns Success with Unit', () async {
        when(
          mockAuthApi.deleteAuthSession(id: anyNamed('id')),
        ).thenAnswer((_) async => dioResponse<void>(null, statusCode: 204));

        final result = await service.deleteAuthSession(id: 1);

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), unit);
        verify(mockAuthApi.deleteAuthSession(id: 1)).called(1);
      });
    });
  });

  // ==========================================================================
  // Metrics
  // ==========================================================================
  group('Metrics', () {
    group('getHistory', () {
      test('returns Success with activity metrics', () async {
        final mockResponse = GetActivityMetrics200Response();
        when(
          mockMetricsApi.getActivityMetrics(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getHistory();

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), mockResponse);
      });
    });

    group('getHistoryClients', () {
      test('forwards default client count', () async {
        final mockResponse = GetClientMetrics200Response();
        when(
          mockMetricsApi.getClientMetrics(N: anyNamed('N')),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getHistoryClients();

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), mockResponse);
        verify(mockMetricsApi.getClientMetrics(N: 10)).called(1);
      });

      test('forwards custom client count', () async {
        final mockResponse = GetClientMetrics200Response();
        when(
          mockMetricsApi.getClientMetrics(N: anyNamed('N')),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getHistoryClients(count: 25);

        expect(result.isSuccess(), true);
        verify(mockMetricsApi.getClientMetrics(N: 25)).called(1);
      });

      test('forwards null to omit the N query parameter', () async {
        final mockResponse = GetClientMetrics200Response();
        when(
          mockMetricsApi.getClientMetrics(N: anyNamed('N')),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getHistoryClients(count: null);

        expect(result.isSuccess(), true);
        verify(mockMetricsApi.getClientMetrics(N: null)).called(1);
      });
    });

    group('getStatsSummary', () {
      test('returns Success with summary', () async {
        final mockResponse = GetMetricsSummary200Response();
        when(
          mockMetricsApi.getMetricsSummary(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getStatsSummary();

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), mockResponse);
      });

      test('returns Failure on DioException', () async {
        when(mockMetricsApi.getMetricsSummary()).thenThrow(dioError());

        final result = await service.getStatsSummary();

        expect(result.isError(), true);
      });
    });

    group('getStatsUpstreams', () {
      test('returns Success with upstreams', () async {
        final mockResponse = GetMetricsUpstreams200Response();
        when(
          mockMetricsApi.getMetricsUpstreams(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getStatsUpstreams();

        expect(result.isSuccess(), true);
      });
    });

    group('getStatsTopDomains', () {
      test('passes parameters correctly', () async {
        final mockResponse = GetMetricsTopDomains200Response();
        when(
          mockMetricsApi.getMetricsTopDomains(
            blocked: anyNamed('blocked'),
            count: anyNamed('count'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getStatsTopDomains(
          blocked: true,
          count: 10,
        );

        expect(result.isSuccess(), true);
        verify(
          mockMetricsApi.getMetricsTopDomains(blocked: true, count: 10),
        ).called(1);
      });
    });

    group('getStatsTopClients', () {
      test('passes parameters correctly', () async {
        final mockResponse = GetMetricsTopClients200Response();
        when(
          mockMetricsApi.getMetricsTopClients(
            blocked: anyNamed('blocked'),
            count: anyNamed('count'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getStatsTopClients(
          blocked: false,
          count: 5,
        );

        expect(result.isSuccess(), true);
        verify(
          mockMetricsApi.getMetricsTopClients(blocked: false, count: 5),
        ).called(1);
      });
    });

    group('getQueryTypes', () {
      test('returns Success with query types', () async {
        final mockResponse = GetMetricsQueryTypes200Response();
        when(
          mockMetricsApi.getMetricsQueryTypes(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getQueryTypes();

        expect(result.isSuccess(), true);
      });
    });

    group('getQueries', () {
      test('passes all parameters correctly', () async {
        final mockResponse = GetQueries200Response();
        when(
          mockMetricsApi.getQueries(
            from: anyNamed('from'),
            until: anyNamed('until'),
            length: anyNamed('length'),
            cursor: anyNamed('cursor'),
            domain: anyNamed('domain'),
            clientIp: anyNamed('clientIp'),
            clientName: anyNamed('clientName'),
            upstream: anyNamed('upstream'),
            type: anyNamed('type'),
            status: anyNamed('status'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getQueries(
          from: 1000.0,
          until: 2000.0,
          length: 100,
          cursor: 50,
          domain: 'example.com',
          clientIp: '192.168.1.1',
          clientName: 'client.local',
          upstream: '8.8.8.8',
          type: 'A',
          status: 'FORWARDED',
        );

        expect(result.isSuccess(), true);
        verify(
          mockMetricsApi.getQueries(
            from: 1000.0,
            until: 2000.0,
            length: 100,
            cursor: 50,
            domain: 'example.com',
            clientIp: '192.168.1.1',
            clientName: 'client.local',
            upstream: '8.8.8.8',
            type: 'A',
            status: 'FORWARDED',
          ),
        ).called(1);
      });
    });
  });

  // ==========================================================================
  // DNS Control
  // ==========================================================================
  group('DNS Control', () {
    group('getDnsBlocking', () {
      test('returns Success', () async {
        final mockResponse = GetBlocking200Response();
        when(
          mockDnsApi.getBlocking(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getDnsBlocking();

        expect(result.isSuccess(), true);
      });
    });

    group('setDnsBlocking', () {
      test('returns Success', () async {
        final mockResponse = GetBlocking200Response();
        when(
          mockDnsApi.setBlocking(setBlockingRequest: anyNamed('setBlockingRequest')),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.setDnsBlocking(
          request: SetBlockingRequest(blocking: true, timer: 60),
        );

        expect(result.isSuccess(), true);
        verify(
          mockDnsApi.setBlocking(
            setBlockingRequest: argThat(
              isA<SetBlockingRequest>().having((r) => r.blocking, 'blocking', true),
              named: 'setBlockingRequest',
            ),
          ),
        ).called(1);
      });
    });
  });

  // ===========================================================================
  // Groups
  // ===========================================================================
  group('Groups', () {
    group('getAllGroups', () {
      test('returns Success', () async {
        final mockResponse = GetGroups200Response();
        when(
          mockGroupApi.getAllGroups(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getAllGroups();

        expect(result.isSuccess(), true);
      });
    });

    group('getGroups', () {
      test('returns Success', () async {
        final mockResponse = GetGroups200Response();
        when(
          mockGroupApi.getGroups(name: anyNamed('name')),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getGroups(name: 'Default');

        expect(result.isSuccess(), true);
      });
    });

    group('addGroup', () {
      test('returns Success', () async {
        final mockResponse = ReplaceGroup200Response();
        when(
          mockGroupApi.addGroup(groupsPost: anyNamed('groupsPost')),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.addGroup(body: GroupsPost(name: 'Test'));

        expect(result.isSuccess(), true);
      });
    });

    group('replaceGroup', () {
      test('returns Success', () async {
        final mockResponse = ReplaceGroup200Response();
        when(
          mockGroupApi.replaceGroup(
            name: anyNamed('name'),
            groupsPut: anyNamed('groupsPut'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.replaceGroup(
          name: 'Test',
          body: GroupsPut(name: 'Updated'),
        );

        expect(result.isSuccess(), true);
      });
    });

    group('deleteGroup', () {
      test('returns Success', () async {
        when(
          mockGroupApi.deleteGroup(name: anyNamed('name')),
        ).thenAnswer((_) async => dioResponse<void>(null, statusCode: 204));

        final result = await service.deleteGroup(name: 'Test');

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), unit);
      });
    });
  });

  // ===========================================================================
  // Domains
  // ===========================================================================
  group('Domains', () {
    group('getDomains', () {
      test('returns Success', () async {
        final mockResponse = GetDomains200Response();
        when(
          mockDomainApi.getDomains(
            type: anyNamed('type'),
            kind: anyNamed('kind'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getDomains(type: 'allow', kind: 'exact');

        expect(result.isSuccess(), true);
      });
    });

    group('getDomain', () {
      test('returns Success', () async {
        final mockResponse = GetDomains200Response();
        when(
          mockDomainApi.getDomain(
            type: anyNamed('type'),
            kind: anyNamed('kind'),
            domain: anyNamed('domain'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getDomain(
          type: 'allow',
          kind: 'exact',
          domain: 'example.com',
        );

        expect(result.isSuccess(), true);
      });
    });

    group('addDomain', () {
      test('returns Success', () async {
        final mockResponse = DomainsPut200Response();
        when(
          mockDomainApi.addDomain(
            type: anyNamed('type'),
            kind: anyNamed('kind'),
            domain: anyNamed('domain'),
            domainsPost: anyNamed('domainsPost'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.addDomain(
          type: 'allow',
          kind: 'exact',
          domain: 'example.com',
        );

        expect(result.isSuccess(), true);
      });
    });

    group('replaceDomain', () {
      test('returns Success', () async {
        final mockResponse = DomainsPut200Response();
        when(
          mockDomainApi.replaceDomain(
            type: anyNamed('type'),
            kind: anyNamed('kind'),
            domain: anyNamed('domain'),
            domainsPut: anyNamed('domainsPut'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.replaceDomain(
          type: 'allow',
          kind: 'exact',
          domain: 'example.com',
        );

        expect(result.isSuccess(), true);
      });
    });

    group('deleteDomain', () {
      test('returns Success', () async {
        when(
          mockDomainApi.deleteDomain(
            type: anyNamed('type'),
            kind: anyNamed('kind'),
            domain: anyNamed('domain'),
          ),
        ).thenAnswer((_) async => dioResponse<void>(null, statusCode: 204));

        final result = await service.deleteDomain(
          type: 'allow',
          kind: 'exact',
          domain: 'example.com',
        );

        expect(result.isSuccess(), true);
      });
    });
  });

  // ===========================================================================
  // Clients
  // ===========================================================================
  group('Clients', () {
    group('getClients', () {
      test('returns Success', () async {
        final mockResponse = GetClients200Response();
        when(
          mockClientApi.getClients(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getClients();

        expect(result.isSuccess(), true);
      });
    });

    group('getClient', () {
      test('returns Success', () async {
        final mockResponse = GetClients200Response();
        when(
          mockClientApi.getClient(client: anyNamed('client')),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getClient(client: '192.168.1.1');

        expect(result.isSuccess(), true);
      });
    });

    group('addClient', () {
      test('returns Success', () async {
        final mockResponse = ClientsPut200Response();
        when(
          mockClientApi.addClient(
            client: anyNamed('client'),
            clientsPost: anyNamed('clientsPost'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.addClient(client: '192.168.1.1');

        expect(result.isSuccess(), true);
      });
    });

    group('replaceClient', () {
      test('returns Success', () async {
        final mockResponse = ClientsPut200Response();
        when(
          mockClientApi.replaceClient(
            client: anyNamed('client'),
            clientsPut: anyNamed('clientsPut'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.replaceClient(client: '192.168.1.1');

        expect(result.isSuccess(), true);
      });
    });

    group('deleteClient', () {
      test('returns Success', () async {
        when(
          mockClientApi.deleteClient(client: anyNamed('client')),
        ).thenAnswer((_) async => dioResponse<void>(null, statusCode: 204));

        final result = await service.deleteClient(client: '192.168.1.1');

        expect(result.isSuccess(), true);
      });
    });
  });

  // ===========================================================================
  // DHCP
  // ===========================================================================
  group('DHCP', () {
    group('getDhcpLeases', () {
      test('returns Success', () async {
        final mockResponse = GetDhcpLeases200Response();
        when(
          mockDhcpApi.getDhcpLeases(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getDhcpLeases();

        expect(result.isSuccess(), true);
      });
    });

    group('deleteDhcpLease', () {
      test('returns Success', () async {
        when(
          mockDhcpApi.deleteDhcpLease(ip: anyNamed('ip')),
        ).thenAnswer((_) async => dioResponse<void>(null, statusCode: 204));

        final result = await service.deleteDhcpLease(ip: '192.168.1.100');

        expect(result.isSuccess(), true);
      });
    });
  });

  // ===========================================================================
  // Lists
  // ===========================================================================
  group('Lists', () {
    group('getLists', () {
      test('returns Success', () async {
        final mockResponse = GetLists200Response();
        when(
          mockListApi.getLists(list: anyNamed('list'), type: anyNamed('type')),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getLists(list: 'adlist', type: 'block');

        expect(result.isSuccess(), true);
      });
    });

    group('addList', () {
      test('returns Success', () async {
        final mockResponse = ListsPut200Response();
        when(
          mockListApi.addList(
            list: anyNamed('list'),
            listsPost: anyNamed('listsPost'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.addList(list: 'https://example.com/list.txt');

        expect(result.isSuccess(), true);
      });
    });

    group('replaceList', () {
      test('returns Success', () async {
        final mockResponse = ListsPut200Response();
        when(
          mockListApi.replaceList(
            list: anyNamed('list'),
            listsPut: anyNamed('listsPut'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.replaceList(list: 'test-list');

        expect(result.isSuccess(), true);
      });
    });

    group('deleteList', () {
      test('returns Success', () async {
        when(
          mockListApi.deleteList(list: anyNamed('list')),
        ).thenAnswer((_) async => dioResponse<void>(null, statusCode: 204));

        final result = await service.deleteList(list: 'test-list');

        expect(result.isSuccess(), true);
      });
    });
  });

  // ===========================================================================
  // FTL Info
  // ===========================================================================
  group('FTL Info', () {
    group('getFtlInfo', () {
      test('returns Success', () async {
        final mockResponse = GetInfoFtl200Response();
        when(
          mockFtlApi.getInfoFtl(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getFtlInfo();

        expect(result.isSuccess(), true);
      });
    });

    group('getSystemInfo', () {
      test('returns Success with system data', () async {
        final mockResponse = GetInfoSystem200Response();
        when(
          mockFtlApi.getInfoSystem(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getSystemInfo();

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), mockResponse);
      });
    });

    group('getHostInfo', () {
      test('returns Success with host data', () async {
        final mockResponse = GetInfoHost200Response();
        when(
          mockFtlApi.getInfoHost(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getHostInfo();

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), mockResponse);
      });
    });

    group('getMessages', () {
      test('returns Success with messages data', () async {
        final mockResponse = GetInfoMessages200Response();
        when(
          mockFtlApi.getInfoMessages(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getMessages();

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), mockResponse);
      });
    });

    group('deleteMessage', () {
      test('returns Success', () async {
        when(
          mockFtlApi.deleteMessage(messageId: anyNamed('messageId')),
        ).thenAnswer((_) async => dioResponse<void>(null, statusCode: 204));

        final result = await service.deleteMessage(messageId: 42);

        expect(result.isSuccess(), true);
      });
    });
  });

  // ===========================================================================
  // Network Info
  // ===========================================================================
  group('Network Info', () {
    group('getGateway', () {
      test('returns Success', () async {
        final mockResponse = GetGateway200Response();
        when(
          mockNetworkApi.getGateway(),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getGateway();

        expect(result.isSuccess(), true);
      });
    });

    group('getNetworkDevices', () {
      test('passes limits through', () async {
        final mockResponse = GetDevices200Response();
        when(
          mockNetworkApi.getDevices(
            maxDevices: anyNamed('maxDevices'),
            maxAddresses: anyNamed('maxAddresses'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getNetworkDevices(
          maxDevices: 50,
          maxAddresses: 5,
        );

        expect(result.isSuccess(), true);
        verify(
          mockNetworkApi.getDevices(maxDevices: 50, maxAddresses: 5),
        ).called(1);
      });
    });

    group('deleteNetworkDevice', () {
      test('returns Success', () async {
        when(
          mockNetworkApi.deleteDevice(deviceId: anyNamed('deviceId')),
        ).thenAnswer((_) async => dioResponse<void>(null, statusCode: 204));

        final result = await service.deleteNetworkDevice(deviceId: 42);

        expect(result.isSuccess(), true);
      });
    });
  });

  // ===========================================================================
  // Config
  // ===========================================================================
  group('Config', () {
    group('getConfig', () {
      test('returns Success', () async {
        final mockResponse = GetConfig200Response();
        when(
          mockConfigApi.getConfig(element: anyNamed('element')),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.getConfig(element: 'dns');

        expect(result.isSuccess(), true);
      });
    });

    group('patchConfig', () {
      test('returns Success', () async {
        final mockResponse = PatchConfig200Response();
        when(
          mockConfigApi.patchConfig(
            element: anyNamed('element'),
            config: anyNamed('config'),
          ),
        ).thenAnswer((_) async => dioResponse(mockResponse));

        final result = await service.patchConfig(element: 'dns');

        expect(result.isSuccess(), true);
      });
    });
  });
}
