import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/app/app_log.dart';
import 'package:pi_hole_client/ui/app_logs/widgets/app_log_details_modal.dart';
import 'package:pi_hole_client/ui/app_logs/widgets/app_logs_screen.dart';
import 'package:pi_hole_client/ui/core/view_models/app_config_viewmodel.dart';

import '../../../testing/fakes/repositories/local/fake_app_config_repository.dart';
import '../../../testing/test_app.dart';

void main() async {
  await initTestApp();

  group('App Log Screen Widget Tests', () {
    late AppConfigViewModel appConfigViewModel;

    setUp(() {
      appConfigViewModel = AppConfigViewModel(FakeAppConfigRepository());
    });

    testWidgets('should show AppLogsScreen screen with one log', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      // mock copy to clipboard
      final log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall methodCall,
          ) async {
            if (methodCall.method == 'Clipboard.setData') {
              log.add(methodCall);
            }
            return null;
          });

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      appConfigViewModel.addLog(
        AppLog(
          type: 'sample',
          dateTime: DateTime(2025, 01, 22, 10, 50, 31),
          message: 'message',
          statusCode: '200',
          resBody: 'body',
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          const AppLogsScreen(),
          appConfigViewModel: appConfigViewModel,
        ),
      );

      expect(find.byType(AppLogsScreen), findsOneWidget);
      await tester.pump();

      expect(find.text('Logs'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);

      expect(find.text('sample'), findsOneWidget);
      expect(find.text('message'), findsOneWidget);
      expect(find.text('2025-01-22 10:50:31.000'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.share));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Logs copied to clipboard'), findsOneWidget);
      expect(log.length, 1);
      expect(log.first.method, 'Clipboard.setData');

      await tester.tap(find.text('sample'));
      await tester.pumpAndSettle();
      expect(find.byType(AppLogDetailsModal), findsOneWidget);
      expect(find.text('Log details'), findsOneWidget);

      // Message tab is selected by default
      expect(find.text('sample'), findsOneWidget);

      await tester.tap(find.text('Status code'));
      await tester.pumpAndSettle();
      expect(find.text('200'), findsOneWidget);

      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();
      expect(find.text('body'), findsOneWidget);
    });


    testWidgets('copied logs and detail modal contain only redacted secrets', (
      WidgetTester tester,
    ) async {
      final clipboard = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall call,
          ) async {
            if (call.method == 'Clipboard.setData') clipboard.add(call);
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      appConfigViewModel.addLog(
        AppLog(
          type: 'connection',
          dateTime: DateTime.utc(2026, 10, 12),
          message: 'Connection failed password="two word password"',
          resBody: '{"access_token":"very private token",'
              '"sid":"session with spaces",'
              '"Authorization":"Basic private-basic-token",'
              '"Cookie":"sid=private-cookie-value",'
              '"apiToken":"private-api-token"}',
        ),
      );
      await tester.pumpWidget(
        buildTestApp(
          const AppLogsScreen(),
          appConfigViewModel: appConfigViewModel,
        ),
      );
      await tester.pump();

      expect(find.textContaining('two word password'), findsNothing);
      await tester.tap(find.byIcon(Icons.share));
      await tester.pump();
      expect(clipboard, hasLength(1));
      final payload = clipboard.single.arguments as Map<Object?, Object?>;
      final exported = jsonDecode(payload['text']! as String) as List<dynamic>;
      final exportedLog = exported.single as Map<String, dynamic>;
      expect(exportedLog['message'], contains('password="<redacted>"'));
      expect(exportedLog['resBody'], contains('"access_token":"<redacted>"'));
      expect(exportedLog['resBody'], contains('"sid":"<redacted>"'));
      final exportedBody = jsonDecode(exportedLog['resBody'] as String)
          as Map<String, dynamic>;
      expect(exportedBody['Authorization'], '<redacted>');
      expect(exportedBody['Cookie'], '<redacted>');
      expect(exportedBody['apiToken'], '<redacted>');
      for (final secret in [
        'two word password',
        'very private token',
        'session with spaces',
        'private-basic-token',
        'private-cookie-value',
        'private-api-token',
      ]) {
        expect(payload['text'], isNot(contains(secret)));
      }

      await tester.tap(find.textContaining('Connection failed'));
      await tester.pumpAndSettle();
      expect(find.byType(AppLogDetailsModal), findsOneWidget);
      expect(find.textContaining('two word password'), findsNothing);
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();
      expect(find.textContaining('very private token'), findsNothing);
      expect(find.textContaining('session with spaces'), findsNothing);
      expect(find.textContaining('private-basic-token'), findsNothing);
      expect(find.textContaining('private-cookie-value'), findsNothing);
      expect(find.textContaining('private-api-token'), findsNothing);
      expect(find.textContaining('<redacted>'), findsWidgets);
    });

    testWidgets('should show blank screen (no app logs)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // No logs added — logs list is empty by default

      await tester.pumpWidget(
        buildTestApp(
          const AppLogsScreen(),
          appConfigViewModel: appConfigViewModel,
        ),
      );

      expect(find.byType(AppLogsScreen), findsOneWidget);
      await tester.pump();

      expect(find.text('Logs'), findsOneWidget);

      // check log message
      expect(find.text('sample'), findsNothing);

      // can't tap on share icon because there are no logs
      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      expect(find.text('Logs copied to clipboard'), findsNothing);
    });
  });
}
