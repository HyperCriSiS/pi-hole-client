import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';

import '../support/app_harness.dart';
import '../support/real_pihole_env.dart';

/// Real-Pi-hole tests for editing a server: alias-only edits, version
/// switches, address replacement, duplicate-address rejection, default
/// promotion, and session cleanup on a failed delete.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!dotenv.isInitialized) {
      try {
        await dotenv.load();
      } catch (_) {
        // .env is optional (Sentry/biometrics disabled in tests).
      }
    }
  });

  group('edit alias', () {
    testWidgets('(E1) an alias-only edit does not touch the session', (
      tester,
    ) async {
      final app = AppHarness(tester);
      await app.boot();
      final uri = Uri.parse(RealPiholeEnv.v6Base);

      await app.openAddServer();
      await app.addV6ServerViaUi(
        host: uri.host,
        port: uri.hasPort ? '${uri.port}' : '',
        password: RealPiholeEnv.v6Password,
        alias: 'em1-original',
      );
      expect(find.text(app.l10n.connectedSuccessfully), findsOneWidget);
      final address = app.servers.getServersList.single.address;
      final sidBefore = await app.sidOf(address);

      await app.editServer(alias: 'em1-renamed');
      expect(find.text(app.l10n.editServerSuccessfully), findsOneWidget);

      expect(app.servers.getServersList.single.alias, 'em1-renamed');
      expect(
        await app.sidOf(address),
        equals(sidBefore),
        reason: 'an alias-only edit must not force a re-login',
      );
    });
  });

  group('v6 to v5 version change', () {
    testWidgets('(X3) switching version replaces the server with a v5 one', (
      tester,
    ) async {
      final app = AppHarness(tester);
      await app.boot();
      final oldUri = Uri.parse(RealPiholeEnv.v6Base);

      await app.openAddServer();
      await app.addV6ServerViaUi(
        host: oldUri.host,
        port: oldUri.hasPort ? '${oldUri.port}' : '',
        password: RealPiholeEnv.v6Password,
        alias: 'em2-v6',
      );
      expect(find.text(app.l10n.connectedSuccessfully), findsOneWidget);
      final oldAddress = app.servers.getServersList.single.address;

      final newUri = Uri.parse(RealPiholeEnv.v5Base);
      await app.editServer(
        version: 'v5',
        host: newUri.host,
        port: newUri.hasPort ? '${newUri.port}' : '',
        token: RealPiholeEnv.v5Token,
      );
      expect(find.text(app.l10n.editServerSuccessfully), findsOneWidget);

      final edited = app.servers.getServersList.single;
      expect(edited.apiVersion, 'v5');
      expect(edited.address, RealPiholeEnv.v5Base);
      expect(edited.address, isNot(oldAddress));
    });
  });

  group('v5 to v6 version change', () {
    testWidgets('(X3) switching version replaces the server with a v6 one', (
      tester,
    ) async {
      final app = AppHarness(tester);
      await app.boot();
      final oldUri = Uri.parse(RealPiholeEnv.v5Base);

      await app.openAddServer();
      await app.addV5ServerViaUi(
        host: oldUri.host,
        port: oldUri.hasPort ? '${oldUri.port}' : '',
        token: RealPiholeEnv.v5Token,
        alias: 'em3-v5',
      );
      expect(find.text(app.l10n.connectedSuccessfully), findsOneWidget);
      final oldAddress = app.servers.getServersList.single.address;

      final newUri = Uri.parse(RealPiholeEnv.v6Base);
      await app.editServer(
        version: 'v6',
        host: newUri.host,
        port: newUri.hasPort ? '${newUri.port}' : '',
        password: RealPiholeEnv.v6Password,
      );
      expect(find.text(app.l10n.editServerSuccessfully), findsOneWidget);

      final edited = app.servers.getServersList.single;
      expect(edited.apiVersion, 'v6');
      expect(edited.address, RealPiholeEnv.v6Base);
      expect(edited.address, isNot(oldAddress));
    });
  });

  group('edit address', () {
    testWidgets('(E2) changing the address replaces the server', (tester) async {
      final app = AppHarness(tester);
      await app.boot();
      final oldUri = Uri.parse(RealPiholeEnv.v6Base);

      await app.openAddServer();
      await app.addV6ServerViaUi(
        host: oldUri.host,
        port: oldUri.hasPort ? '${oldUri.port}' : '',
        password: RealPiholeEnv.v6Password,
        alias: 'em4-old',
      );
      expect(find.text(app.l10n.connectedSuccessfully), findsOneWidget);

      final newUri = Uri.parse(RealPiholeEnv.v6AltBase);
      await app.editServer(
        host: newUri.host,
        port: newUri.hasPort ? '${newUri.port}' : '',
        password: RealPiholeEnv.v6Password,
        alias: 'em4-new',
      );
      expect(find.text(app.l10n.editServerSuccessfully), findsOneWidget);

      final edited = app.servers.getServersList.single;
      expect(edited.address, RealPiholeEnv.v6AltBase);
      expect(edited.alias, 'em4-new');
    });
  });

  group('duplicate address', () {
    testWidgets('(E3) editing to an existing address is rejected', (tester) async {
      final app = AppHarness(tester);
      await app.boot();
      final firstUri = Uri.parse(RealPiholeEnv.v6Base);
      final secondUri = Uri.parse(RealPiholeEnv.v6AltBase);

      await app.openAddServer();
      await app.addV6ServerViaUi(
        host: firstUri.host,
        port: firstUri.hasPort ? '${firstUri.port}' : '',
        password: RealPiholeEnv.v6Password,
        alias: 'em5-first',
      );
      expect(find.text(app.l10n.connectedSuccessfully), findsOneWidget);

      await app.openAddServer();
      await app.addV6ServerViaUi(
        host: secondUri.host,
        port: secondUri.hasPort ? '${secondUri.port}' : '',
        password: RealPiholeEnv.v6Password,
        alias: 'em5-second',
      );
      expect(find.text(app.l10n.connectedSuccessfully), findsOneWidget);

      await tester.tap(
        find.widgetWithText(NavigationDestination, app.l10n.settings),
      );
      await app.settle(frames: 10);
      await tester.tap(find.widgetWithText(ListTile, app.l10n.servers));
      await app.settle(frames: 10);

      await app.openServerMenu('em5-second');
      await tester.tap(find.text(app.l10n.edit));
      await app.settle(frames: 10);

      final hostField = find.byType(TextField).at(0);
      final portField = find.byType(TextField).at(1);
      await tester.enterText(hostField, firstUri.host);
      await tester.enterText(
        portField,
        firstUri.hasPort ? '${firstUri.port}' : '',
      );
      await tester.tap(find.text(app.l10n.save));
      await app.settle(frames: 10);

      expect(find.text(app.l10n.serverAlreadyExists), findsOneWidget);
    });
  });

  group('default promotion', () {
    testWidgets('(E4) deleting the default promotes another server', (
      tester,
    ) async {
      final app = AppHarness(tester);
      await app.boot();
      final firstUri = Uri.parse(RealPiholeEnv.v6Base);
      final secondUri = Uri.parse(RealPiholeEnv.v6AltBase);

      await app.openAddServer();
      await app.addV6ServerViaUi(
        host: firstUri.host,
        port: firstUri.hasPort ? '${firstUri.port}' : '',
        password: RealPiholeEnv.v6Password,
        alias: 'em6-default',
      );
      expect(find.text(app.l10n.connectedSuccessfully), findsOneWidget);

      await app.openAddServer();
      await app.addV6ServerViaUi(
        host: secondUri.host,
        port: secondUri.hasPort ? '${secondUri.port}' : '',
        password: RealPiholeEnv.v6Password,
        alias: 'em6-other',
      );
      expect(find.text(app.l10n.connectedSuccessfully), findsOneWidget);

      await tester.tap(
        find.widgetWithText(NavigationDestination, app.l10n.settings),
      );
      await app.settle(frames: 10);
      await tester.tap(find.widgetWithText(ListTile, app.l10n.servers));
      await app.settle(frames: 10);

      await app.deleteServer('em6-default');
      expect(app.servers.getServersList, hasLength(1));
      expect(app.servers.getServersList.single.alias, 'em6-other');
      expect(app.servers.getServersList.single.defaultServer, isTrue);
    });
  });

  group('edit v6 to v5 through fault-delete proxy', () {
    testWidgets(
      '(X3) a faulted old-session logout leaves it to time out (accepted)',
      (tester) async {
        final app = AppHarness(tester);
        await app.boot();

        // Add/connect (auth + blocking status) succeed here; only a later
        // DELETE /api/auth is faulted with 401.
        final oldUri = Uri.parse(RealPiholeEnv.faultDeleteBase);
        await app.openAddServer();
        await app.addV6ServerViaUi(
          host: oldUri.host,
          port: oldUri.hasPort ? '${oldUri.port}' : '',
          password: RealPiholeEnv.v6Password,
          alias: 'edit-old-v6',
        );
        expect(find.text(app.l10n.connectedSuccessfully), findsOneWidget);
        await app.connectServer();

        final oldAddress = app.servers.getServersList.single.address;
        final oldSid = await app.sidOf(oldAddress);
        expect(oldSid, isNotNull);

        // Settings > Servers (the bottom nav has no direct "connect" tab).
        await tester.tap(
          find.widgetWithText(NavigationDestination, app.l10n.settings),
        );
        await app.settle(frames: 10);
        await tester.tap(find.widgetWithText(ListTile, app.l10n.servers));
        await app.settle(frames: 10);

        final newUri = Uri.parse(RealPiholeEnv.v5Base);
        await app.editServer(
          version: 'v5',
          host: newUri.host,
          port: newUri.hasPort ? '${newUri.port}' : '',
          token: RealPiholeEnv.v5Token,
        );
        expect(find.text(app.l10n.editServerSuccessfully), findsOneWidget);

        // Accepted behavior (not ideal): the old server's DELETE /api/auth is
        // faulted (faultDeleteBase), so the logout can't complete. The version
        // switch still succeeds, and the old v6 session is simply left to time
        // out server-side -- the app does not force it. See the "Known
        // limitation" note on deleteCurrentSession in
        // lib/data/repositories/api/v6/auth_repository.dart (a failed delete
        // renews instead of retrying; low impact, left as-is).
        final authService = PiholeV6Service.fromConnection(
          url: RealPiholeEnv.v6Base,
        );
        authService.setSid(oldSid!);
        final result = await authService.getAuth();
        expect(
          result.getOrThrow().session.valid,
          isTrue,
          reason: 'a faulted logout leaves the old session valid until timeout',
        );
      },
    );
  });
}
