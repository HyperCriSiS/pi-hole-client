import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';

import 'mocks.mocks.dart';

Response<T> _dioResponse<T>(T data) {
  return Response(
    data: data,
    statusCode: 200,
    requestOptions: RequestOptions(),
  );
}

void main() {
  late MockPiholeV6Api api;
  late MockMetricsApi metricsApi;
  late PiholeV6Service service;

  setUp(() {
    api = MockPiholeV6Api();
    metricsApi = MockMetricsApi();
    when(api.getMetricsApi()).thenReturn(metricsApi);
    service = PiholeV6Service(api: api);
  });

  Future<void> stubResponse() async {
    final response = GetClientMetrics200Response();
    when(
      metricsApi.getClientMetrics(N: anyNamed('N')),
    ).thenAnswer((_) async => _dioResponse(response));
  }

  test('forwards default history client count as N=10', () async {
    await stubResponse();

    final result = await service.getHistoryClients();

    expect(result.isSuccess(), true);
    verify(metricsApi.getClientMetrics(N: 10)).called(1);
  });

  test('forwards custom history client count', () async {
    await stubResponse();

    final result = await service.getHistoryClients(count: 25);

    expect(result.isSuccess(), true);
    verify(metricsApi.getClientMetrics(N: 25)).called(1);
  });

  test('passes null so generated client omits N', () async {
    await stubResponse();

    final result = await service.getHistoryClients(count: null);

    expect(result.isSuccess(), true);
    verify(metricsApi.getClientMetrics(N: null)).called(1);
  });
}
