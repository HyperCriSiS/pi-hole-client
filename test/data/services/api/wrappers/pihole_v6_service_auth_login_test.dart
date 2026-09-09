import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/services/api/utils/api_exception.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';

class _AuthTransportInterceptor extends Interceptor {
  RequestOptions? lastRequest;
  int? errorStatus;
  String? errorKey;
  String? errorMessage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    lastRequest = options;
    final status = errorStatus;
    if (status != null) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: status,
            data: <String, dynamic>{
              'error': <String, dynamic>{
                'key': errorKey,
                'message': errorMessage,
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    handler.resolve(
      Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{
          'session': <String, dynamic>{
            'valid': true,
            'totp': false,
            'sid': 'new-sid',
            'csrf': 'csrf-token',
            'validity': 300,
            'message': 'correct password',
          },
          'took': 0.001,
        },
      ),
    );
  }
}

Map<String, dynamic> _requestBody(RequestOptions request) {
  final data = request.data;
  if (data is String) {
    return Map<String, dynamic>.from(jsonDecode(data) as Map);
  }
  return Map<String, dynamic>.from(data as Map);
}

void main() {
  late Dio dio;
  late PiholeV6Api api;
  late PiholeV6Service service;
  late _AuthTransportInterceptor transport;
  late ApiKeyAuthInterceptor sharedAuthInterceptor;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
    api = PiholeV6Api(dio: dio);
    transport = _AuthTransportInterceptor();
    dio.interceptors.add(transport);
    service = PiholeV6Service(api: api);
    service.setSid('existing-sid');
    sharedAuthInterceptor = dio.interceptors
        .whereType<ApiKeyAuthInterceptor>()
        .single;
  });

  test('generated password login is unauthenticated and preserves shared SID', () async {
    final result = await service.postAuth(password: 'secret');

    expect(result.isSuccess(), isTrue);
    expect(result.getOrNull()?.session.sid, 'new-sid');
    expect(transport.lastRequest, isNotNull);
    expect(transport.lastRequest!.method, 'POST');
    expect(transport.lastRequest!.path, '/auth');
    expect(transport.lastRequest!.headers.containsKey('X-FTL-SID'), isFalse);
    expect(_requestBody(transport.lastRequest!), <String, dynamic>{
      'password': 'secret',
    });
    expect(sharedAuthInterceptor.apiKeys['x_header_sid'], 'existing-sid');
  });

  test('injects numeric TOTP after generated password serialization', () async {
    final result = await service.postAuth(password: 'secret', totp: 123456);

    expect(result.isSuccess(), isTrue);
    expect(_requestBody(transport.lastRequest!), <String, dynamic>{
      'password': 'secret',
      'totp': 123456,
    });
    expect(transport.lastRequest!.headers.containsKey('X-FTL-SID'), isFalse);
    expect(sharedAuthInterceptor.apiKeys['x_header_sid'], 'existing-sid');
  });

  test('maps missing TOTP response to TotpRequiredException', () async {
    transport
      ..errorStatus = 400
      ..errorKey = 'bad_request'
      ..errorMessage = 'No 2FA token found in JSON payload';

    final result = await service.postAuth(password: 'secret');

    expect(result.exceptionOrNull(), isA<TotpRequiredException>());
  });

  test('maps invalid TOTP response to TotpInvalidException', () async {
    transport
      ..errorStatus = 401
      ..errorKey = 'unauthorized'
      ..errorMessage = 'Invalid 2FA token';

    final result = await service.postAuth(password: 'secret', totp: 111111);

    expect(result.exceptionOrNull(), isA<TotpInvalidException>());
  });

  test('maps reused TOTP response to TotpReusedException', () async {
    transport
      ..errorStatus = 401
      ..errorKey = 'unauthorized'
      ..errorMessage = 'Reused 2FA token';

    final result = await service.postAuth(password: 'secret', totp: 123456);

    expect(result.exceptionOrNull(), isA<TotpReusedException>());
  });

  test('maps TOTP throttling response to TotpRateLimitException', () async {
    transport
      ..errorStatus = 429
      ..errorKey = 'rate_limiting'
      ..errorMessage = 'Rate-limiting 2FA token requests, try again later';

    final result = await service.postAuth(password: 'secret', totp: 123456);

    expect(result.exceptionOrNull(), isA<TotpRateLimitException>());
  });

  test('keeps non-TOTP generated auth failures as ApiException', () async {
    transport
      ..errorStatus = 401
      ..errorKey = 'unauthorized'
      ..errorMessage = 'Invalid password';

    final result = await service.postAuth(password: 'wrong');

    final error = result.exceptionOrNull();
    expect(error, isA<ApiException>());
    final apiError = error! as ApiException;
    expect(apiError.statusCode, 401);
    expect(apiError.errorCode, 'unauthorized');
  });
}
