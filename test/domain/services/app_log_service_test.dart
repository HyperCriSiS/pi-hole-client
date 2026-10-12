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
