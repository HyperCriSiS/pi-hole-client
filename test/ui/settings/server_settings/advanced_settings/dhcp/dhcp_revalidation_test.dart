import 'dart:async';

import 'package:command_it/command_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/dhcp/dhcp.dart';
import 'package:pi_hole_client/ui/core/ui/components/error_message.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/dhcp/view_models/dhcp_viewmodel.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/dhcp/widgets/dhcp_screen.dart';
import 'package:result_dart/result_dart.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../../../testing/fakes/repositories/api/fake_dhcp_repository.dart';
import '../../../../../../testing/fakes/repositories/api/fake_ftl_repository.dart';
import '../../../../../../testing/test_app.dart';

class _ControlledDhcpRepository extends FakeDhcpRepository {
  Completer<Result<List<DhcpLease>>>? pending;

  @override
  Future<Result<List<DhcpLease>>> fetchDhcpLeases() async {
    final request = pending;
    if (request != null) return request.future;
    return super.fetchDhcpLeases();
  }
}

void main() async {
  await initTestApp();

  group('DHCP revalidation', () {
    late _ControlledDhcpRepository dhcpRepository;
    late DhcpViewModel viewModel;

    setUp(() {
      Command.globalExceptionHandler = (_, _) {};
      dhcpRepository = _ControlledDhcpRepository();
      viewModel = DhcpViewModel(
        dhcpRepository: dhcpRepository,
        ftlRepository: FakeFtlRepository(),
      );
    });

    tearDown(() {
      viewModel.dispose();
      Command.globalExceptionHandler = null;
    });

    testWidgets('keeps loaded leases visible while refresh is pending', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await viewModel.loadLeases.runAsync().timeout(
          const Duration(seconds: 8),
        );
      });
      expect(viewModel.hasLoadedSuccessfully, isTrue);
      await tester.pumpWidget(buildTestApp(DhcpScreen(viewModel: viewModel)));
      await tester.pumpAndSettle();
      expect(find.text('raspberrypi'), findsOneWidget);

      final pending = Completer<Result<List<DhcpLease>>>();
      dhcpRepository.pending = pending;
      await tester.runAsync(() async {
        viewModel.loadLeases.run();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      expect(viewModel.loadLeases.isRunning.value, isTrue);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('dhcp-refresh-progress')),
        findsOneWidget,
      );
      expect(find.text('raspberrypi'), findsOneWidget);
      expect(find.byType(Skeletonizer), findsNothing);
      final refresh = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.refresh_rounded),
      );
      expect(refresh.onPressed, isNull);

      dhcpRepository.pending = null;
      pending.complete(Success(viewModel.data.leases));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('dhcp-refresh-progress')),
        findsNothing,
      );
      expect(find.text('raspberrypi'), findsOneWidget);
    });

    testWidgets('failed refresh retains leases and clears warning on retry', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await viewModel.loadLeases.runAsync().timeout(
          const Duration(seconds: 8),
        );
      });
      await tester.pumpWidget(buildTestApp(DhcpScreen(viewModel: viewModel)));
      await tester.pumpAndSettle();

      dhcpRepository.shouldFail = true;
      await tester.runAsync(() async {
        try {
          await viewModel.loadLeases.runAsync().timeout(
            const Duration(seconds: 8),
          );
        } catch (_) {
          // Keep cached data and expose the command error to the UI.
        }
      });
      await tester.pumpAndSettle();
      expect(viewModel.loadLeases.errors.value, isNotNull);
      expect(find.textContaining('Refresh failed.'), findsOneWidget);
      expect(find.text('raspberrypi'), findsOneWidget);
      expect(find.byType(ErrorMessage), findsNothing);

      dhcpRepository.shouldFail = false;
      await tester.runAsync(() async {
        await viewModel.loadLeases.runAsync().timeout(
          const Duration(seconds: 8),
        );
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('Refresh failed.'), findsNothing);
      expect(find.text('raspberrypi'), findsOneWidget);
    });
  });
}
