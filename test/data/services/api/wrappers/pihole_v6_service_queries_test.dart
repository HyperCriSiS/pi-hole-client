import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';

import 'mocks.mocks.dart';

Response<T> _response<T>(T data) {
  return Response(
    data: data,
    statusCode: 200,
    requestOptions: RequestOptions(),
  );
}

void main() {
  test(
    'forwards all supported query parameters to generated MetricsApi',
    () async {
      final api = MockPiholeV6Api();
      final metricsApi = MockMetricsApi();
      final response = GetQueries200Response();

      when(api.getMetricsApi()).thenReturn(metricsApi);
      when(
        metricsApi.getQueries(
          from: 1000,
          until: 2000,
          length: 100,
          start: 25,
          cursor: 7,
          domain: 'example.com',
          clientIp: '192.0.2.10',
          clientName: 'desktop',
          upstream: '1.1.1.1',
          type: 'AAAA',
          status: 'FORWARDED',
          reply: 'IP',
          dnssec: 'SECURE',
        ),
      ).thenAnswer((_) async => _response(response));

      final service = PiholeV6Service(api: api);
      final result = await service.getQueries(
        from: 1000,
        until: 2000,
        length: 100,
        start: 25,
        cursor: 7,
        domain: 'example.com',
        clientIp: '192.0.2.10',
        clientName: 'desktop',
        upstream: '1.1.1.1',
        type: 'AAAA',
        status: 'FORWARDED',
        reply: 'IP',
        dnssec: 'SECURE',
      );

      expect(result.getOrNull(), response);
      verify(
        metricsApi.getQueries(
          from: 1000,
          until: 2000,
          length: 100,
          start: 25,
          cursor: 7,
          domain: 'example.com',
          clientIp: '192.0.2.10',
          clientName: 'desktop',
          upstream: '1.1.1.1',
          type: 'AAAA',
          status: 'FORWARDED',
          reply: 'IP',
          dnssec: 'SECURE',
        ),
      ).called(1);
    },
  );
}
