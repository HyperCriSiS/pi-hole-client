import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/app/app_log.dart';
import 'package:pi_hole_client/domain/services/app_log_service.dart';

void main() {
  group('AppLogService', () {
    test('redacts credentials and sensitive HTTP headers', () {
      final service = AppLogService();

      service.addDiagnostic(
        type: 'auth',
        message:
            'password=super-secret token=api-secret sid=session-secret '
            'totp=123456\nAuthorization: Bearer auth-secret\n'
            'Cookie: session=cookie-secret',
      );

      final message = service.logs.single.message;
      expect(message, contains('<redacted>'));
      expect(message, isNot(contains('super-secret')));
      expect(message, isNot(contains('api-secret')));
      expect(message, isNot(contains('session-secret')));
      expect(message, isNot(contains('123456')));
      expect(message, isNot(contains('auth-secret')));
      expect(message, isNot(contains('cookie-secret')));
    });

    test('redacts existing AppLog message and response body', () {
      final service = AppLogService();

      service.addLog(
        AppLog(
          type: 'connection',
          dateTime: DateTime(2026, 8, 14),
          message: '{"password":"secret-value"}',
          resBody: '{"sid":"sid-value","token":"token-value"}',
        ),
      );

      final log = service.logs.single;
      expect(log.message, isNot(contains('secret-value')));
      expect(log.resBody, isNot(contains('sid-value')));
      expect(log.resBody, isNot(contains('token-value')));
    });


    test('redacts complete JSON quoted and escaped credentials', () {
      final service = AppLogService();
      final input = jsonEncode(<String, Object>{
        'password': 'two words secret',
        'access_token': 'access secret with spaces',
        'refreshToken': 'refresh secret with spaces',
        'authToken': 'auth token with spaces',
        'client_secret': 'client secret with spaces',
        'sid': 'quoted "SID" and second word',
        'totp': 123456,
        'safe': 'ordinary context stays readable',
      });
      service.addLog(
        AppLog(
          type: 'auth',
          dateTime: DateTime.utc(2026, 10, 12),
          message: input,
          resBody: input,
        ),
      );

      final output = service.logs.single;
      for (final text in [output.message, output.resBody!]) {
        final data = jsonDecode(text) as Map<String, dynamic>;
        for (final key in [
          'password',
          'access_token',
          'refreshToken',
          'authToken',
          'client_secret',
          'sid',
          'totp',
        ]) {
          expect(data[key], '<redacted>', reason: key);
        }
        expect(data['safe'], 'ordinary context stays readable');
        expect(text, isNot(contains('second word')));
        expect(text, isNot(contains('secret with spaces')));
      }
    });

    test('redacts JSON-serialized auth headers and token aliases', () {
      final service = AppLogService();
      final payload = jsonEncode(<String, Object>{
        'headers': <String, Object>{
          'Authorization': 'Basic encoded-private-credential',
          'proxyAuthorization': 'Negotiate private-session',
          'Cookie': 'sid=cookie-private; path=/',
          'setCookie': 'login=opaque-cookie; HttpOnly',
          'X-API-Key': 'api-key-private',
        },
        'credentials': <String, Object>{
          'apiToken': 'api token with whitespace',
          'id_token': 'jwt-token-private',
          'privateKey': 'private-key-private',
          'clientSecret': 'camel case private',
        },
        'flags': <String, Object>{
          'requestId': 'safe-request-id',
          'isAuthenticated': false,
        },
      });

      service.addDiagnostic(type: 'transport', message: payload, resBody: payload);

      final log = service.logs.single;
      for (final text in [log.message, log.resBody!]) {
        final data = jsonDecode(text) as Map<String, dynamic>;
        final headers = data['headers'] as Map<String, dynamic>;
        final credentials = data['credentials'] as Map<String, dynamic>;
        for (final key in [
          'Authorization',
          'proxyAuthorization',
          'Cookie',
          'setCookie',
          'X-API-Key',
        ]) {
          expect(headers[key], '<redacted>', reason: key);
        }
        for (final key in [
          'apiToken',
          'id_token',
          'privateKey',
          'clientSecret',
        ]) {
          expect(credentials[key], '<redacted>', reason: key);
        }
        final flags = data['flags'] as Map<String, dynamic>;
        expect(flags['requestId'], 'safe-request-id');
        expect(flags['isAuthenticated'], false);
      }
    });

    test('unquoted aliases and JSON scalar secrets stay redacted', () {
      final service = AppLogService();
      service.addDiagnostic(
        type: 'auth',
        message: 'apiToken=my-private-token idToken=another-private-token '
            'proxyAuthorization=opaque-auth-value',
        resBody: jsonEncode(<String, Object>{
          'apiToken': 123456,
          'Authorization': true,
          'Cookie': false,
          'safe': 42,
        }),
      );
      final log = service.logs.single;
      expect(log.message, contains('apiToken=<redacted>'));
      expect(log.message, contains('idToken=<redacted>'));
      expect(log.message, contains('proxyAuthorization=<redacted>'));
      expect(log.message, isNot(contains('private-token')));
      expect(log.message, isNot(contains('opaque-auth-value')));
      final data = jsonDecode(log.resBody!) as Map<String, dynamic>;
      expect(data['apiToken'], '<redacted>');
      expect(data['Authorization'], '<redacted>');
      expect(data['Cookie'], '<redacted>');
      expect(data['safe'], 42);
    });

    test('redacts URL credentials, query keys and bare bearer tokens', () {
      final service = AppLogService();
      service.addDiagnostic(
        type: 'transport',
        message: 'GET https://name:uri-password@local.example/api'
            '?api_key=query-secret&size=10 '
            'Bearer bare-credential',
        resBody: 'password="quoted phrase and another word" '
            'token=unquoted-value '
            'Authorization: Bearer header-credential\n'
            'Set-Cookie: sid=cookie-value',
      );
      final log = service.logs.single;
      for (final field in [log.message, log.resBody!]) {
        for (final secret in [
          'uri-password',
          'query-secret',
          'bare-credential',
          'quoted phrase',
          'another word',
          'unquoted-value',
          'header-credential',
          'cookie-value',
        ]) {
          expect(field, isNot(contains(secret)), reason: secret);
        }
      }
      expect(log.message, contains('size=10'));
      expect(log.message, contains('https://<redacted>@local.example'));
      expect(log.resBody, contains('Authorization: <redacted>'));
      expect(log.resBody, contains('Set-Cookie: <redacted>'));
    });

    test('notifies listeners when a log is added', () {
      final service = AppLogService();
      var notifications = 0;
      service.addListener(() => notifications++);

      service.addDiagnostic(type: 'connection', message: 'failed');

      expect(notifications, 1);
      expect(service.logs, hasLength(1));
    });
  });
}
