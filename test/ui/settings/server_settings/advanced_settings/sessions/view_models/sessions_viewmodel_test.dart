import 'dart:async';

import 'package:command_it/command_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/sessions/view_models/sessions_viewmodel.dart';

import '../../../../../../../testing/fakes/repositories/api/fake_auth_repository.dart';
import '../../../../../../../testing/models/v6/auth.dart';

void main() {
  group('SessionsViewModel', () {
    late FakeAuthRepository fakeAuthRepository;
    late SessionsViewModel viewModel;

    setUp(() {
      Command.globalExceptionHandler = (_, _) {};
      fakeAuthRepository = FakeAuthRepository();
      viewModel = SessionsViewModel(authRepository: fakeAuthRepository);
    });

    tearDown(() {
      viewModel.dispose();
      Command.globalExceptionHandler = null;
    });

    test('loadSessions success populates sessions list', () async {
      await viewModel.loadSessions.runAsync();

      expect(viewModel.sessions, equals(kRepoGetAllSessions));
      expect(viewModel.sessions.length, 3);
    });

    test('loadSessions failure sets error', () async {
      fakeAuthRepository.shouldFail = true;

      final completer = Completer<void>();
      viewModel.loadSessions.errors.addListener(() {
        if (!completer.isCompleted) completer.complete();
      });
      viewModel.loadSessions.run();
      await completer.future;

      expect(viewModel.loadSessions.errors.value, isNotNull);
    });

    test('loadSessions failure and retry notify screen listeners', () async {
      var sawLoading = false;
      var sawError = false;
      var sawRecovered = false;
      final errorNotified = Completer<void>();

      viewModel.addListener(() {
        final isLoading = viewModel.loadSessions.isRunning.value;
        final hasError = viewModel.loadSessions.errors.value != null;
        if (isLoading) sawLoading = true;
        if (hasError) {
          sawError = true;
          if (!errorNotified.isCompleted) errorNotified.complete();
        }
        if (sawError && !isLoading && !hasError) {
          sawRecovered = true;
        }
      });

      fakeAuthRepository.shouldFail = true;
      viewModel.loadSessions.run();
      await errorNotified.future;
      await Future<void>.delayed(Duration.zero);

      expect(sawLoading, isTrue);
      expect(sawError, isTrue);
      expect(viewModel.loadSessions.isRunning.value, isFalse);

      fakeAuthRepository.shouldFail = false;
      await viewModel.loadSessions.runAsync();

      expect(viewModel.loadSessions.errors.value, isNull);
      expect(viewModel.loadSessions.isRunning.value, isFalse);
      expect(sawRecovered, isTrue);
    });


    test('deleteSession success removes session locally', () async {
      await viewModel.loadSessions.runAsync();
      expect(fakeAuthRepository.getAllSessionsCallCount, 1);

      await viewModel.deleteSession.runAsync(0);

      // No re-fetch — local state update only
      expect(fakeAuthRepository.getAllSessionsCallCount, 1);
      expect(viewModel.sessions.length, 2);
      expect(viewModel.sessions.any((s) => s.id == 0), isFalse);
    });

    test('deleteSession failure sets error', () async {
      // First load sessions successfully
      await viewModel.loadSessions.runAsync();

      // Now make repository fail
      fakeAuthRepository.shouldFail = true;

      final completer = Completer<void>();
      viewModel.deleteSession.errors.addListener(() {
        if (!completer.isCompleted) completer.complete();
      });
      viewModel.deleteSession.run(0);
      await completer.future;

      expect(viewModel.deleteSession.errors.value, isNotNull);
    });

    test('deleteSession failure does not call global handler', () async {
      var globalCalled = false;
      Command.globalExceptionHandler = (_, _) => globalCalled = true;
      await viewModel.loadSessions.runAsync();
      fakeAuthRepository.shouldFail = true;

      await expectLater(viewModel.deleteSession.runAsync(0), throwsA(anything));

      expect(globalCalled, isFalse);
    });

    test('isRunning is true while loading', () async {
      final future = viewModel.loadSessions.runAsync();

      // isRunning should be true during execution
      expect(viewModel.loadSessions.isRunning.value, isTrue);

      await future;

      expect(viewModel.loadSessions.isRunning.value, isFalse);
    });

    test('notifies listeners on state changes', () async {
      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      await viewModel.loadSessions.runAsync();

      expect(notifyCount, greaterThan(0));
    });
  });
}
