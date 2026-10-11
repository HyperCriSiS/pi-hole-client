import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';
import 'package:pi_hole_client/ui/servers/view_models/multi_server_overview_controller.dart';
import 'package:pi_hole_client/ui/servers/widgets/multi_server_overview_dialog.dart';

void main() {
  testWidgets('opening makes zero requests; manual refresh renders per-server data', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: MultiServerOverviewDialog(
            servers: const [
              Server(address: 'http://a', alias: 'Pi A', apiVersion: 'v5'),
              Server(address: 'http://b', alias: 'Pi B', apiVersion: 'v6'),
            ],
            reader: (server) async {
              calls++;
              if (server.alias == 'Pi A') throw StateError('secret');
              return const ServerOverviewMetrics(
                queries: 150, blocked: 30, blockedPercentage: 20,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Not queried yet'), findsNWidgets(2));
    await tester.tap(find.text('Refresh all servers'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Pi A'), findsOneWidget);
    expect(find.text('Pi B'), findsOneWidget);
    expect(find.text('Total queries: 150'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.text('Could not retrieve statistics. Other servers are unaffected.'), findsOneWidget);
  });
}
