import 'dart:async';

import 'package:command_it/command_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/network/network.dart';
import 'package:pi_hole_client/ui/core/ui/components/error_message.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/network/view_models/network_viewmodel.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/network/widgets/network_screen.dart';
import 'package:result_dart/result_dart.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../../../testing/fakes/repositories/api/fake_ftl_repository.dart';
import '../../../../../../testing/fakes/repositories/api/fake_network_repository.dart';
import '../../../../../../testing/test_app.dart';

class _ControlledNetworkRepository extends FakeNetworkRepository {
  Completer<Result<List<Device>>>? pending;

  @override
  Future<Result<List<Device>>> fetchDevices({
    int? maxDevices = 999,
    int? maxAddresses = 25,
  }) async {
    final request = pending;
    if (request != null) return request.future;
    return super.fetchDevices(
      maxDevices: maxDevices,
      maxAddresses: maxAddresses,
    );
  }
}

void main() async {
  await initTestApp();

  group('Network revalidation', () {
    late _ControlledNetworkRepository networkRepository;
    late NetworkViewModel viewModel;

    setUp(() {
      Command.globalExceptionHandler = (_, _) {};
      networkRepository = _ControlledNetworkRepository();
      viewModel = NetworkViewModel(
        networkRepository: networkRepository,
        ftlRepository: FakeFtlRepository(),
      );
    });

    tearDown(() {
      viewModel.dispose();
      Command.globalExceptionHandler = null;
    });

    testWidgets('keeps loaded devices visible while refresh is pending', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await viewModel.loadDevices.runAsync().timeout(
          const Duration(seconds: 8),
        );
      });
      expect(viewModel.hasLoadedSuccessfully, isTrue);
      await tester.pumpWidget(buildTestApp(NetworkScreen(viewModel: viewModel)));
      await tester.pumpAndSettle();
      expect(find.text('192.168.1.51 (ubuntu-server)'), findsOneWidget);

      final pending = Completer<Result<List<Device>>>();
      networkRepository.pending = pending;
      await tester.runAsync(() async {
        viewModel.loadDevices.run();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      expect(viewModel.loadDevices.isRunning.value, isTrue);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('network-refresh-progress')),
        findsOneWidget,
      );
      expect(find.text('192.168.1.51 (ubuntu-server)'), findsOneWidget);
      expect(find.byType(Skeletonizer), findsNothing);
      final refresh = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.refresh_rounded),
      );
      expect(refresh.onPressed, isNull);

      networkRepository.pending = null;
      pending.complete(Success(viewModel.data.devices));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('network-refresh-progress')),
        findsNothing,
      );
      expect(find.text('192.168.1.51 (ubuntu-server)'), findsOneWidget);
    });

    testWidgets('failed refresh retains devices and clears warning on retry', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await viewModel.loadDevices.runAsync().timeout(
          const Duration(seconds: 8),
        );
      });
      await tester.pumpWidget(buildTestApp(NetworkScreen(viewModel: viewModel)));
      await tester.pumpAndSettle();

      networkRepository.shouldFail = true;
      await tester.runAsync(() async {
        try {
          await viewModel.loadDevices.runAsync().timeout(
            const Duration(seconds: 8),
          );
        } catch (_) {
          // Preserve last successful data until a successful retry.
        }
      });
      await tester.pumpAndSettle();
      expect(viewModel.loadDevices.errors.value, isNotNull);
      expect(find.textContaining('Refresh failed.'), findsOneWidget);
      expect(find.text('192.168.1.51 (ubuntu-server)'), findsOneWidget);
      expect(find.byType(ErrorMessage), findsNothing);

      networkRepository.shouldFail = false;
      await tester.runAsync(() async {
        await viewModel.loadDevices.runAsync().timeout(
          const Duration(seconds: 8),
        );
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('Refresh failed.'), findsNothing);
      expect(find.text('192.168.1.51 (ubuntu-server)'), findsOneWidget);
    });
  });
}
