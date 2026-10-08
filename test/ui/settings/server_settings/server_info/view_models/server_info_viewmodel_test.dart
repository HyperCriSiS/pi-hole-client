import 'dart:async';

import 'package:command_it/command_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/server/connection_diagnostics.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';
import 'package:pi_hole_client/ui/settings/server_settings/server_info/view_models/server_info_viewmodel.dart';

import '../../../../../../testing/fakes/repositories/api/fake_auth_repository.dart';
import '../../../../../../testing/fakes/repositories/api/fake_config_repository.dart';
import '../../../../../../testing/fakes/repositories/api/fake_ftl_repository.dart';
import '../../../../../../testing/models/v6/ftl.dart';

const _server = Server(
  address: 'https://pi.hole/pihole',
  alias: 'Test Server',
  apiVersion: 'v6',
  allowUntrustedCert: true,
  pinnedCertificateSha256: 'AA:BB',
);

void main() {
  group('ServerInfoViewModel', () {
    late FakeFtlRepository fakeFtlRepository;
    late FakeAuthRepository fakeAuthRepository;
    late FakeConfigRepository fakeConfigRepository;
    late ConnectionSessionState sessionState;
    late ServerInfoViewModel viewModel;

    setUp(() {
      Command.globalExceptionHandler = (_, _) {};
      fakeFtlRepository = FakeFtlRepository();
      fakeAuthRepository = FakeAuthRepository();
      fakeConfigRepository = FakeConfigRepository();
      sessionState = ConnectionSessionState.active;
      viewModel = ServerInfoViewModel(
        ftlRepository: fakeFtlRepository,
        authRepository: fakeAuthRepository,
        configRepository: fakeConfigRepository,
        server: _server,
        connectionSessionStateProvider: () => sessionState,
      );
    });

    tearDown(() {
      viewModel.dispose();
      Command.globalExceptionHandler = null;
    });

    test('loadServerInfo success populates server info', () async {
      await viewModel.loadServerInfo.runAsync();

      expect(viewModel.loadServerInfo.value, equals(kRepoFetchAllServerInfo));
      expect(viewModel.loadServerInfo.value.host, isNotNull);
      expect(viewModel.loadServerInfo.value.version, isNotNull);
    });

    test('loadServerInfo failure sets error', () async {
      fakeFtlRepository.shouldFail = true;

      final completer = Completer<void>();
      viewModel.loadServerInfo.errors.addListener(() {
        if (!completer.isCompleted) completer.complete();
      });
      viewModel.loadServerInfo.run();
      await completer.future;

      expect(viewModel.loadServerInfo.errors.value, isNotNull);
    });

    test('loadServerInfo failure and retry notify screen listeners', () async {
      var sawLoading = false;
      var sawError = false;
      var sawRecovered = false;
      final errorNotified = Completer<void>();

      viewModel.addListener(() {
        final isLoading = viewModel.loadServerInfo.isRunning.value;
        final hasError = viewModel.loadServerInfo.errors.value != null;
        if (isLoading) sawLoading = true;
        if (hasError) {
          sawError = true;
          if (!errorNotified.isCompleted) errorNotified.complete();
        }
        if (sawError && !isLoading && !hasError) {
          sawRecovered = true;
        }
      });

      fakeFtlRepository.shouldFail = true;
      viewModel.loadServerInfo.run();
      await errorNotified.future;
      await Future<void>.delayed(Duration.zero);

      expect(sawLoading, isTrue);
      expect(sawError, isTrue);
      expect(viewModel.loadServerInfo.isRunning.value, isFalse);

      fakeFtlRepository.shouldFail = false;
      await viewModel.loadServerInfo.runAsync();

      expect(viewModel.loadServerInfo.errors.value, isNull);
      expect(viewModel.loadServerInfo.isRunning.value, isFalse);
      expect(sawRecovered, isTrue);
    });


    test('isRunning is true while loading', () async {
      final future = viewModel.loadServerInfo.runAsync();

      expect(viewModel.loadServerInfo.isRunning.value, isTrue);

      await future;

      expect(viewModel.loadServerInfo.isRunning.value, isFalse);
    });

    test('notifies listeners on state changes', () async {
      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      await viewModel.loadServerInfo.runAsync();

      expect(notifyCount, greaterThan(0));
    });

    test('mfaEnabled is true when server uses 2FA', () async {
      fakeAuthRepository.serverUsesTotp = true;
      await viewModel.loadServerInfo.runAsync();
      expect(viewModel.mfaEnabled, isTrue);
    });

    test('mfaEnabled is false when server does not use 2FA', () async {
      fakeAuthRepository.serverUsesTotp = false;
      await viewModel.loadServerInfo.runAsync();
      expect(viewModel.mfaEnabled, isFalse);
    });

    test('mfaEnabled is null when 2FA status is unavailable', () async {
      fakeAuthRepository.shouldFail = true;
      await viewModel.loadServerInfo.runAsync();
      expect(viewModel.mfaEnabled, isNull);
    });

    test('builds read-only connection diagnostics from existing state', () async {
      fakeConfigRepository
        ..webPanelPrefix = '/proxy'
        ..webPanelHome = '/admin2/';
      fakeAuthRepository.serverUsesTotp = true;

      await viewModel.loadServerInfo.runAsync();

      final diagnostics = viewModel.connectionDiagnostics;
      expect(diagnostics, isNotNull);
      expect(diagnostics!.apiVersion, 'v6');
      expect(
        diagnostics.ftlVersion,
        kRepoFetchAllServerInfo.version!.ftl.local.version,
      );
      expect(diagnostics.apiBasePath, '/pihole/api/');
      expect(diagnostics.webPanelPath, '/proxy/admin2/');
      expect(diagnostics.mfaEnabled, isTrue);
      expect(diagnostics.sessionState, ConnectionSessionState.active);
      expect(diagnostics.tlsPolicy, ConnectionTlsPolicy.httpsPinned);
    });

    test(
      'web path capability failure falls back without failing server info',
      () async {
        fakeConfigRepository.shouldFailWebPanelPaths = true;

        await viewModel.loadServerInfo.runAsync();

        expect(viewModel.loadServerInfo.errors.value, isNull);
        expect(viewModel.connectionDiagnostics?.webPanelPath, '/pihole/admin/');
      },
    );

    test('reads session state from provider without changing it', () async {
      sessionState = ConnectionSessionState.interactiveReauthRequired;

      await viewModel.loadServerInfo.runAsync();

      expect(
        viewModel.connectionDiagnostics?.sessionState,
        ConnectionSessionState.interactiveReauthRequired,
      );
      expect(sessionState, ConnectionSessionState.interactiveReauthRequired);
    });
  });
}
