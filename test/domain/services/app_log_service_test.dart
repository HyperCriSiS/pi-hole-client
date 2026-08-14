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
