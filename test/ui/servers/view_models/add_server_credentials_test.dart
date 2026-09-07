import 'package:command_it/command_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/server/api_versions.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';
import 'package:pi_hole_client/ui/core/view_models/servers_viewmodel.dart';
import 'package:pi_hole_client/ui/servers/view_models/add_server_viewmodel.dart';
import 'package:result_dart/result_dart.dart';

import '../../../../testing/fakes/repositories/api/fake_auth_repository.dart';
import '../../../../testing/fakes/repositories/api/fake_dns_repository.dart';
import '../../../../testing/fakes/repositories/local/fake_server_repository.dart';
import '../../../../testing/fakes/viewmodels/fake_status_viewmodel.dart';
import '../../../../testing/test_app.dart';

class _CredentialFailureRepository extends FakeServerRepository {
  _CredentialFailureRepository({
    this.failPasswordWrite = false,
    this.failTokenWrite = false,
  });

  final bool failPasswordWrite;
  final bool failTokenWrite;

  @override
  Future<Result<bool>> doesServerExist(String url) async =>
      const Success(false);

  @override
  Future<Result<void>> savePassword(String address, String password) async {
    savePasswordCallCount++;
    lastSavedPasswordAddress = address;
    lastSavedPassword = password;
    if (failPasswordWrite) {
      return Failure(Exception('forced password write failure'));
    }
    return Success.unit();
  }

  @override
  Future<Result<void>> saveToken(String address, String token) async {
    saveTokenCallCount++;
    lastSavedTokenAddress = address;
    lastSavedToken = token;
    if (failTokenWrite) {
      return Failure(Exception('forced token write failure'));
    }
    return Success.unit();
  }
}

void main() {
  setUp(() => Command.globalExceptionHandler = (_, _) {});
  tearDown(() => Command.globalExceptionHandler = null);

  Future<
    ({
      CreateOutcome outcome,
      _CredentialFailureRepository repo,
      FakeAuthRepository auth,
    })
  >
  runCreate({required bool failPassword, required bool failToken}) async {
    final repo = _CredentialFailureRepository(
      failPasswordWrite: failPassword,
      failTokenWrite: failToken,
    );
    final servers = ServersViewModel(repo);
    final status = FakeStatusViewModel();
    final auth = FakeAuthRepository();
    final dns = FakeDnsRepository();
    final vm = AddServerViewModel(
      serversViewModel: servers,
      statusViewModel: status,
      createBundle: ({required server}) => createFakeRepositoryBundle(
        auth: auth,
        dns: dns,
        serverAddress: server.address,
        apiVersion: server.apiVersion,
      ),
    );
    addTearDown(vm.dispose);
    addTearDown(servers.dispose);
    addTearDown(status.dispose);

    final outcome = await vm.createServer.runAsync(
      CreateServerRequest(
        url: 'http://pi.hole',
        alias: 'Pi-hole',
        apiVersion: SupportedApiVersions.v6,
        allowUntrustedCert: true,
        ignoreCertificateErrors: false,
        pinnedCertificateSha256: null,
        password: 'password-value',
        token: 'token-value',
        defaultServer: false,
        resolveCertificate: (Server server) async => server,
        resolveTotp: ({error}) async => null,
      ),
    );

    return (outcome: outcome, repo: repo, auth: auth);
  }

  test('password persistence failure aborts before authentication', () async {
    final result = await runCreate(failPassword: true, failToken: false);

    expect(result.outcome, isA<CreateDbError>());
    expect(result.repo.savePasswordCallCount, 1);
    expect(result.repo.saveTokenCallCount, 0);
    expect(result.repo.insertCallCount, 0);
    expect(result.auth.createSessionCallCount, 0);
  });

  test('token persistence failure aborts before authentication', () async {
    final result = await runCreate(failPassword: false, failToken: true);

    expect(result.outcome, isA<CreateDbError>());
    expect(result.repo.savePasswordCallCount, 1);
    expect(result.repo.saveTokenCallCount, 1);
    expect(result.repo.insertCallCount, 0);
    expect(result.auth.createSessionCallCount, 0);
  });
}
