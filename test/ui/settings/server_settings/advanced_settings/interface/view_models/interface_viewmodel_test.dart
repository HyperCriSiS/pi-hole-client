import 'dart:async';

import 'package:command_it/command_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/interface/view_models/interface_viewmodel.dart';

import '../../../../../../../testing/fakes/repositories/api/fake_network_repository.dart';
import '../../../../../../../testing/models/v6/network.dart';

void main() {
  group('InterfaceViewModel', () {
    late FakeNetworkRepository fakeNetworkRepository;
    late InterfaceViewModel viewModel;

    setUp(() {
      Command.globalExceptionHandler = (_, _) {};
      fakeNetworkRepository = FakeNetworkRepository();
      viewModel = InterfaceViewModel(networkRepository: fakeNetworkRepository);
    });

    tearDown(() {
      viewModel.dispose();
      Command.globalExceptionHandler = null;
    });

    test('loadInterfaces success populates interfaces', () async {
      await viewModel.loadInterfaces.runAsync();

      expect(
        viewModel.loadInterfaces.value,
        equals(kRepoFetchGatewaysDetailed.interfaces),
      );
      expect(viewModel.loadInterfaces.value.length, 1);
      expect(viewModel.loadInterfaces.value.first.name, 'eth0');
    });

    test('keeps last successful result after failed revalidation and retry', () async {
      expect(viewModel.hasLoadedSuccessfully, isFalse);
      await viewModel.loadInterfaces.runAsync();
      expect(viewModel.hasLoadedSuccessfully, isTrue);
      expect(viewModel.interfaces, equals(kRepoFetchGatewaysDetailed.interfaces));

      fakeNetworkRepository.shouldFail = true;
      await expectLater(
        viewModel.loadInterfaces.runAsync(),
        throwsA(isA<Exception>()),
      );
      expect(viewModel.hasLoadedSuccessfully, isTrue);
      expect(viewModel.interfaces, equals(kRepoFetchGatewaysDetailed.interfaces));

      fakeNetworkRepository.shouldFail = false;
      await viewModel.loadInterfaces.runAsync();
      expect(viewModel.loadInterfaces.errors.value, isNull);
      expect(viewModel.interfaces, equals(kRepoFetchGatewaysDetailed.interfaces));
    });

    test('loadInterfaces failure sets error', () async {
      fakeNetworkRepository.shouldFail = true;

      final completer = Completer<void>();
      viewModel.loadInterfaces.errors.addListener(() {
        if (!completer.isCompleted) completer.complete();
      });
      viewModel.loadInterfaces.run();
      await completer.future;

      expect(viewModel.loadInterfaces.errors.value, isNotNull);
    });

    test('loadInterfaces failure and retry notify screen listeners', () async {
      var sawLoading = false;
      var sawError = false;
      var sawRecovered = false;
      final errorNotified = Completer<void>();

      viewModel.addListener(() {
        final isLoading = viewModel.loadInterfaces.isRunning.value;
        final hasError = viewModel.loadInterfaces.errors.value != null;
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
      viewModel.loadInterfaces.run();
      await errorNotified.future;
      await Future<void>.delayed(Duration.zero);

      expect(sawLoading, isTrue);
      expect(sawError, isTrue);
      expect(viewModel.loadInterfaces.isRunning.value, isFalse);

      fakeNetworkRepository.shouldFail = false;
      await viewModel.loadInterfaces.runAsync();

      expect(viewModel.loadInterfaces.errors.value, isNull);
      expect(viewModel.loadInterfaces.isRunning.value, isFalse);
      expect(sawRecovered, isTrue);
    });


    test('isRunning is true while loading', () async {
      final future = viewModel.loadInterfaces.runAsync();

      expect(viewModel.loadInterfaces.isRunning.value, isTrue);

      await future;

      expect(viewModel.loadInterfaces.isRunning.value, isFalse);
    });

    test('notifies listeners on state changes', () async {
      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      await viewModel.loadInterfaces.runAsync();

      expect(notifyCount, greaterThan(0));
    });
  });
}
