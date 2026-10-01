import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/server/api_versions.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';
import 'package:pi_hole_client/ui/core/actions/refresh_with_totp_recovery.dart';
import 'package:pi_hole_client/ui/core/view_models/app_config_viewmodel.dart';
import 'package:pi_hole_client/utils/exceptions.dart';

import '../../../../testing/fakes/repositories/api/fake_auth_repository.dart';
import '../../../../testing/fakes/repositories/api/fake_dns_repository.dart';
import '../../../../testing/fakes/repositories/local/fake_app_config_repository.dart';
import '../../../../testing/fakes/viewmodels/fake_servers_viewmodel.dart';
import '../../../../testing/fakes/viewmodels/fake_status_viewmodel.dart';
import '../../../../testing/test_app.dart';

const _serverV6 = Server(
  address: 'http://localhost:8081',
  alias: 'v6',
  apiVersion: SupportedApiVersions.v6,
  defaultServer: false,
  allowUntrustedCert: true,
  ignoreCertificateErrors: false,
);

void main() async {
  await initTestApp();

  group('refreshWithTotpRecovery', () {
    late FakeServersViewModel serversViewModel;
    late FakeStatusViewModel statusViewModel;
    late AppConfigViewModel appConfigViewModel;
    late FakeAuthRepository authRepository;
    late FakeDnsRepository dnsRepository;

    setUp(() {
      serversViewModel = FakeServersViewModel();
      statusViewModel = FakeStatusViewModel();
      appConfigViewModel = AppConfigViewModel(FakeAppConfigRepository());
      authRepository = FakeAuthRepository();
      dnsRepository = FakeDnsRepository();
    });

    Future<BuildContext> pumpContext(WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
          appConfigViewModel: appConfigViewModel,
          serversViewModel: serversViewModel,
          statusViewModel: statusViewModel,
          createRepositoryBundle: ({required server}) =>
              createFakeRepositoryBundle(
                auth: authRepository,
                dns: dnsRepository,
                serverAddress: server.address,
                apiVersion: server.apiVersion,
              ),
        ),
      );
      await tester.pump();
      return ctx;
    }

    testWidgets('runs load once and clears declined state on success', (
      tester,
    ) async {
      serversViewModel.selectedServer = _serverV6;
      serversViewModel.markTotpReauthDeclined(_serverV6.address);
      final ctx = await pumpContext(tester);

      var loadCalls = 0;
      await refreshWithTotpRecovery(ctx, () async {
        loadCalls++;
      });

      expect(loadCalls, 1);
      expect(
        serversViewModel.isTotpReauthDeclined(_serverV6.address),
        isFalse,
      );
      expect(authRepository.createSessionCallCount, 0);
    });

    testWidgets('recovers TOTP and retries the requested load once', (
      tester,
    ) async {
      serversViewModel.selectedServer = _serverV6;
      final ctx = await pumpContext(tester);

      var loadCalls = 0;
      await refreshWithTotpRecovery(ctx, () async {
        loadCalls++;
        if (loadCalls == 1) {
          throw TotpRequiredException();
        }
      });
      await tester.pumpAndSettle();

      expect(loadCalls, 2);
    });

    testWidgets('does not retry when session recovery fails', (tester) async {
      serversViewModel.selectedServer = _serverV6;
      dnsRepository
        ..shouldFail = true
        ..failureException = HttpStatusCodeException(503, 'unavailable');
      final ctx = await pumpContext(tester);

      var loadCalls = 0;
      await refreshWithTotpRecovery(ctx, () async {
        loadCalls++;
        throw TotpRequiredException();
      });
      await tester.pumpAndSettle();

      expect(loadCalls, 1);
    });

    testWidgets('rethrows non-TOTP errors without reauthentication', (
      tester,
    ) async {
      serversViewModel.selectedServer = _serverV6;
      final ctx = await pumpContext(tester);

      var loadCalls = 0;
      await expectLater(
        refreshWithTotpRecovery(ctx, () async {
          loadCalls++;
          throw HttpStatusCodeException(500, 'boom');
        }),
        throwsA(isA<HttpStatusCodeException>()),
      );

      expect(loadCalls, 1);
      expect(authRepository.createSessionCallCount, 0);
    });
  });
}
