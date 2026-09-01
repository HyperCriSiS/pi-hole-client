import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';
import 'package:result_dart/result_dart.dart';

import 'mocks.mocks.dart';

Response<T> _dioResponse<T>(T data) {
  return Response(data: data, requestOptions: RequestOptions());
}

void main() {
  test('getNetworkDevices forwards device and address limits', () async {
    final api = MockPiholeV6Api();
    final networkApi = MockNetworkInformationApi();
    final response = GetNetwork200Response();

    when(api.getNetworkInformationApi()).thenReturn(networkApi);
    when(
      networkApi.getNetwork(
        maxDevices: anyNamed('maxDevices'),
        maxAddresses: anyNamed('maxAddresses'),
      ),
    ).thenAnswer((_) async => _dioResponse(response));

    final service = PiholeV6Service(api: api);
    final result = await service.getNetworkDevices(
      maxDevices: 17,
      maxAddresses: 4,
    );

    expect(result.getOrNull(), response);
    verify(networkApi.getNetwork(maxDevices: 17, maxAddresses: 4)).called(1);
  });
}
