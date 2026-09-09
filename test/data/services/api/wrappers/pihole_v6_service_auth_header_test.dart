import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';

class _RecordingInterceptor extends Interceptor {
  RequestOptions? lastRequest;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    lastRequest = options;
    handler.resolve(
      Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{
          'session': <String, dynamic>{
            'valid': false,
            'totp': true,
            'sid': null,
            'validity': 0,
            'message': 'unauthenticated',
          },
          'took': 0.001,
        },
      ),
    );
  }
}

void main() {
  test(
    'unauthenticated auth probe omits SID without mutating shared auth state',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
      final api = PiholeV6Api(dio: dio);
      final recorder = _RecordingInterceptor();
      dio.interceptors.add(recorder);
      final service = PiholeV6Service(api: api);

      service.setSid('sid-123');
      final sharedAuthInterceptor = dio.interceptors
          .whereType<ApiKeyAuthInterceptor>()
          .single;

      final result = await service.getAuthUnauthenticated();

      expect(result.isSuccess(), isTrue);
      expect(result.getOrNull()?.session.totp, isTrue);
      expect(recorder.lastRequest, isNotNull);
      expect(recorder.lastRequest!.headers.containsKey('X-FTL-SID'), isFalse);
      expect(
        dio.interceptors.whereType<ApiKeyAuthInterceptor>().single,
        same(sharedAuthInterceptor),
      );
      expect(sharedAuthInterceptor.apiKeys['x_header_sid'], 'sid-123');
    },
  );
}
