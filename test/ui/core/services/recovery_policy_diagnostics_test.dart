import 'package:command_it/command_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/server/api_versions.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';
import 'package:pi_hole_client/ui/core/view_models/app_config_viewmodel.dart';
import 'package:pi_hole_client/ui/servers/view_models/add_server_viewmodel.dart';

import '../../../../testing/fakes/repositories/api/fake_auth_repository.dart';
import '../../../../testing/fakes/repositories/api/fake_dns_repository.dart';
import '../../../../testing/fakes/repositories/local/fake_app_config_repository.dart';
import '../../../../testing/fakes/viewmodels/fake_servers_viewmodel.dart';
import '../../../../testing/fakes/viewmodels/fake_status_viewmodel.dart';
import '../../../../testing/test_app.dart';

const _server = Server(
  address: 'http://localhost:8081',
  alias: 'server',
  apiVersion: SupportedApiVersions.v6,
  defaultServer: false,
  allowUntrustedCert: true,
  ignoreCertificateErrors: false,
);

void main() {
  group('connection recovery policy', () {
    late FakeServersViewModel serversViewModel;
    late FakeStatusViewModel statusViewModel;
    late FakeAuthRepository authRepository;
    late FakeDnsRepository dnsRepository;

    setUp(() {
      Command.globalExceptionHandler = (_, _) {};
      serversViewModel = FakeServersViewModel()..selectedServer = _server;
      statusViewModel = FakeStatusViewModel();
      authRepository = FakeAuthRepository();
      dnsRepository = FakeDnsRepository();
    });

    tearDown(() {
      Command.globalExceptionHandler = null;
    });

    AddServerViewModel buildViewModel() {
      final vm = AddServerViewModel(
        serversViewModel: serversViewModel,
        statusViewModel: statusViewModel,
        createBundle: ({required server}) => createFakeRepositoryBundle(
          auth: authRepository,
          dns: dnsRepository,
          serverAddress: server.address,
          apiVersion: server.apiVersion,
        ),
      );
      addTearDown(vm.dispose);
      return vm;
    }

    UpdateServerRequest request() => UpdateServerRequest(
      url: _server.address,
      alias: _server.alias,
      apiVersion: _server.apiVersion,
      allowUntrustedCert: _server.allowUntrustedCert,
      ignoreCertificateErrors: _server.ignoreCertificateErrors,
      pinnedCertificateSha256: _server.pinnedCertificateSha256,
      password: 'new-pass',
      token: 'token',
      defaultServer: false,
      oldServer: _server,
      initPassword: 'old-pass',
      initToken: 'token',
      secretsLoadSucceeded: true,
      resolveCertificate: (server) async => server,
      resolveTotp: ({error}) async => null,
    );

    test(
      'edit TOTP cancellation marks reauth declined before auto-refresh resumes',
      () async {
        authRepository.shouldRequireTotp = true;
        final vm = buildViewModel();

        final outcome = await vm.updateServer.runAsync(request());

        expect(outcome, isA<UpdateCancelled>());
        expect(
          serversViewModel.isTotpReauthDeclined(_server.address),
          isTrue,
        );
        expect(statusViewModel.startAutoRefreshCallCount, 1);
      },
    );

    test('successful edit clears a prior reauth-declined marker', () async {
      serversViewModel.markTotpReauthDeclined(_server.address);
      final vm = buildViewModel();

      final outcome = await vm.updateServer.runAsync(
        UpdateServerRequest(
          url: _server.address,
          alias: _server.alias,
          apiVersion: _server.apiVersion,
          allowUntrustedCert: _server.allowUntrustedCert,
          ignoreCertificateErrors: _server.ignoreCertificateErrors,
          pinnedCertificateSha256: _server.pinnedCertificateSha256,
          password: 'old-pass',
          token: 'token',
          defaultServer: false,
          oldServer: _server,
          initPassword: 'old-pass',
          initToken: 'token',
          secretsLoadSucceeded: true,
          resolveCertificate: (server) async => server,
          resolveTotp: ({error}) async => null,
        ),
      );

      expect(outcome, isA<UpdateSuccess>());
      expect(
        serversViewModel.isTotpReauthDeclined(_server.address),
        isFalse,
      );
    });
  });

  test('AppConfig diagnostics use the shared redacting App Log sink', () {
    final viewModel = AppConfigViewModel(FakeAppConfigRepository());
    addTearDown(viewModel.dispose);

    viewModel.addDiagnostic(
      type: 'auth',
      message: 'Authentication failed password=super-secret',
    );

    expect(viewModel.logs, hasLength(1));
    expect(viewModel.logs.single.type, 'auth');
    expect(viewModel.logs.single.message, contains('password=<redacted>'));
    expect(viewModel.logs.single.message, isNot(contains('super-secret')));
  });
}
