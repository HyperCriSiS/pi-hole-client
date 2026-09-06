import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/domain/services/app_log_service.dart';
import 'package:pi_hole_client/utils/exceptions.dart';

import '../../../../../testing/fakes/services/fake_pihole_v6_api_client.dart';
import '../../../../../testing/fakes/services/fake_session_credential_service.dart';

void main() {
  group('V6SessionCache diagnostics', () {
    test('storage read failure is surfaced in App Logs', () async {
      final appLogs = AppLogService();
      final creds = FakeSessionCredentialService()..shouldFailRead = true;
      final cache = V6SessionCache(
        creds: creds,
        client: FakePiholeV6ApiClient(),
        appLogService: appLogs,
      );

      await expectLater(cache.getSid(), throwsA(isA<SidNotFoundException>()));

      expect(appLogs.logs, isNotEmpty);
      expect(appLogs.logs.last.type, 'session');
      expect(appLogs.logs.last.message, contains('session restore failed'));
    });

    test('failed SID persistence is logged and does not stay cached', () async {
      final appLogs = AppLogService();
      final creds = FakeSessionCredentialService()..shouldFailSave = true;
      final cache = V6SessionCache(
        creds: creds,
        client: FakePiholeV6ApiClient(),
        appLogService: appLogs,
      );

      await expectLater(
        cache.saveSid('sid-secret-value'),
        throwsA(isA<Exception>()),
      );

      expect(appLogs.logs, hasLength(1));
      expect(appLogs.logs.single.type, 'session');
      expect(
        appLogs.logs.single.message,
        contains('session could not be persisted'),
      );
      expect(appLogs.logs.single.message, isNot(contains('sid-secret-value')));

      creds
        ..shouldFailSave = false
        ..addressSid = 'sid-from-storage';
      expect(await cache.getSid(), 'sid-from-storage');
    });
  });
}
