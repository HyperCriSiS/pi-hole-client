import 'package:command_it/command_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/server/connection_diagnostics.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';
import 'package:pi_hole_client/ui/core/ui/components/error_message.dart';
import 'package:pi_hole_client/ui/settings/server_settings/server_info/view_models/server_info_viewmodel.dart';
import 'package:pi_hole_client/ui/settings/server_settings/server_info/widgets/connection_diagnostics_section.dart';
import 'package:pi_hole_client/ui/settings/server_settings/server_info/widgets/host_information_section.dart';
import 'package:pi_hole_client/ui/settings/server_settings/server_info/widgets/performance_usage_section.dart';
import 'package:pi_hole_client/ui/settings/server_settings/server_info/widgets/pihole_version_section.dart';
import 'package:pi_hole_client/ui/settings/server_settings/server_info/widgets/server_connection_section.dart';
import 'package:pi_hole_client/ui/settings/server_settings/server_info/widgets/server_info_screen.dart';

import '../../../../../testing/fakes/repositories/api/fake_auth_repository.dart';
import '../../../../../testing/fakes/repositories/api/fake_config_repository.dart';
import '../../../../../testing/fakes/repositories/api/fake_ftl_repository.dart';
import '../../../../../testing/test_app.dart';

const _server = Server(
  address: 'http://192.168.1.100',
  alias: 'Test Server',
  apiVersion: 'v6',
);

void main() async {
  await initTestApp();

  group('ServerInfoScreen tests', () {
    late FakeFtlRepository fakeFtlRepository;
    late FakeAuthRepository fakeAuthRepository;
    late FakeConfigRepository fakeConfigRepository;
    late ServerInfoViewModel viewModel;

    setUp(() async {
      Command.globalExceptionHandler = (_, _) {};
      fakeFtlRepository = FakeFtlRepository();
      fakeAuthRepository = FakeAuthRepository();
      fakeConfigRepository = FakeConfigRepository();
      viewModel = ServerInfoViewModel(
        ftlRepository: fakeFtlRepository,
        authRepository: fakeAuthRepository,
        configRepository: fakeConfigRepository,
        server: _server,
        connectionSessionStateProvider: () => ConnectionSessionState.active,
      );
    });

    tearDown(() {
      viewModel.dispose();
      Command.globalExceptionHandler = null;
    });

    Widget buildServerInfoWidget() {
      return buildTestApp(
        ServerInfoScreen(
          viewModel: viewModel..loadServerInfo.run(),
          serverAlias: _server.alias,
          serverAddress: _server.address,
        ),
      );
    }

    testWidgets('should show server info sections on success', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildServerInfoWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ServerInfoScreen), findsOneWidget);
      expect(find.byType(ServerConnectionSection), findsOneWidget);
      expect(find.byType(ConnectionDiagnosticsSection), findsOneWidget);
      expect(find.byType(HostInformationSection), findsOneWidget);
      expect(find.byType(PerformanceUsageSection), findsOneWidget);
      expect(find.byType(PiholeVersionSection), findsOneWidget);

      expect(find.text('Test Server'), findsOneWidget);
      expect(find.text('http://192.168.1.100'), findsOneWidget);

      expect(find.text('V6'), findsOneWidget);
      expect(find.text('/api/'), findsOneWidget);
      expect(find.text('/admin/'), findsOneWidget);
      expect(find.text('Valid'), findsOneWidget);
      expect(find.text('HTTP'), findsOneWidget);
    });

    testWidgets('should show error screen when fetching fails', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      fakeFtlRepository.shouldFail = true;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        viewModel.loadServerInfo.run();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });

      await tester.pumpWidget(
        buildTestApp(
          ServerInfoScreen(
            viewModel: viewModel,
            serverAlias: _server.alias,
            serverAddress: _server.address,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ServerInfoScreen), findsOneWidget);
      expect(find.byType(ErrorMessage), findsOneWidget);
    });

    testWidgets('should show refresh button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildServerInfoWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ServerInfoScreen), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('should show MFA enabled when server uses 2FA', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      fakeAuthRepository.serverUsesTotp = true;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildServerInfoWidget());
      await tester.pumpAndSettle();

      expect(find.text('MFA'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
    });

    testWidgets('should show MFA disabled when server does not use 2FA', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      fakeAuthRepository.serverUsesTotp = false;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildServerInfoWidget());
      await tester.pumpAndSettle();

      expect(find.text('MFA'), findsOneWidget);
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('should show MFA N/A when 2FA status is unavailable', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      fakeAuthRepository.shouldFail = true;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildServerInfoWidget());
      await tester.pumpAndSettle();

      expect(find.text('MFA'), findsOneWidget);
      expect(find.text('N/A'), findsOneWidget);
    });
  });
}
