import 'dart:async';

import 'package:command_it/command_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/network/view_models/network_viewmodel.dart';

import '../../../../../../../testing/fakes/repositories/api/fake_ftl_repository.dart';
import '../../../../../../../testing/fakes/repositories/api/fake_network_repository.dart';
import '../../../../../../../testing/models/v6/ftl.dart';
import '../../../../../../../testing/models/v6/network.dart';

void main() {
  group('NetworkViewModel', () {
    late FakeNetworkRepository fakeNetworkRepository;
    late FakeFtlRepository fakeFtlRepository;
    late NetworkViewModel viewModel;

    setUp(() {
      Command.globalExceptionHandler = (_, _) {};
      fakeNetworkRepository = FakeNetworkRepository();
      fakeFtlRepository = FakeFtlRepository();
      viewModel = NetworkViewModel(
        networkRepository: fakeNetworkRepository,
        ftlRepository: fakeFtlRepository,
      );
    });

    tearDown(() {
      viewModel.dispose();
      Command.globalExceptionHandler = null;
    });

    test('loadDevices success populates devices and client IP', () async {
      await viewModel.loadDevices.runAsync();

      expect(viewModel.data.devices, equals(kRepoFetchDevices));
      expect(viewModel.data.devices.length, 2);
      expect(viewModel.data.currentClientIp, equals(kRepoFetchFtlClient.addr));
    });

    test('loadDevices failure sets error', () async {
      fakeNetworkRepository.shouldFail = true;

      final completer = Completer<void>();
      viewModel.loadDevices.errors.addListener(() {
        if (!completer.isCompleted) completer.complete();
      });
      viewModel.loadDevices.run();
      await completer.future;

      expect(viewModel.loadDevices.errors.value, isNotNull);
    });

    test('loadDevices failure and retry notify screen listeners', () async {
      var sawLoading = false;
      var sawError = false;
      var sawRecovered = false;
      final errorNotified = Completer<void>();

      viewModel.addListener(() {
        final isLoading = viewModel.loadDevices.isRunning.value;
        final hasError = viewModel.loadDevices.errors.value != null;
        if (isLoading) sawLoading = true;
        if (hasError) {
          sawError = true;
          if (!errorNotified.isCompleted) errorNotified.complete();
        }
        if (sawError && !isLoading && !hasError) {
          sawRecovered = true;
        }
      });

      fakeNetworkRepository.shouldFail = true;
      viewModel.loadDevices.run();
      await errorNotified.future;
      await Future<void>.delayed(Duration.zero);

      expect(sawLoading, isTrue);
      expect(sawError, isTrue);
      expect(viewModel.loadDevices.isRunning.value, isFalse);

      fakeNetworkRepository.shouldFail = false;
      await viewModel.loadDevices.runAsync();

      expect(viewModel.loadDevices.errors.value, isNull);
      expect(viewModel.loadDevices.isRunning.value, isFalse);
      expect(sawRecovered, isTrue);
    });


    test('deleteDevice success removes device locally', () async {
      await viewModel.loadDevices.runAsync();
      expect(fakeNetworkRepository.fetchDevicesCallCount, 1);

      await viewModel.deleteDevice.runAsync(1);

      // No re-fetch — local state update only
      expect(fakeNetworkRepository.fetchDevicesCallCount, 1);
      expect(viewModel.data.devices.length, 1);
      expect(viewModel.data.devices.any((d) => d.id == 1), isFalse);
      expect(viewModel.data.currentClientIp, equals(kRepoFetchFtlClient.addr));
    });

    test('deleteDevice failure sets error', () async {
      await viewModel.loadDevices.runAsync();

      fakeNetworkRepository.shouldFail = true;

      final completer = Completer<void>();
      viewModel.deleteDevice.errors.addListener(() {
        if (!completer.isCompleted) completer.complete();
      });
      viewModel.deleteDevice.run(1);
      await completer.future;

      expect(viewModel.deleteDevice.errors.value, isNotNull);
    });

    test('deleteDevice failure does not call global handler', () async {
      var globalCalled = false;
      Command.globalExceptionHandler = (_, _) => globalCalled = true;
      await viewModel.loadDevices.runAsync();
      fakeNetworkRepository.shouldFail = true;

      await expectLater(viewModel.deleteDevice.runAsync(1), throwsA(anything));

      expect(globalCalled, isFalse);
    });

    test('isRunning is true while loading', () async {
      final future = viewModel.loadDevices.runAsync();

      expect(viewModel.loadDevices.isRunning.value, isTrue);

      await future;

      expect(viewModel.loadDevices.isRunning.value, isFalse);
    });

    test('notifies listeners on state changes', () async {
      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      await viewModel.loadDevices.runAsync();

      expect(notifyCount, greaterThan(0));
    });
  });
}
