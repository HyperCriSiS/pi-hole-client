import 'dart:async';

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
    expect(find.textContaining('Snapshot captured:'), findsNothing);
    await tester.tap(find.text('Refresh all servers'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Pi A'), findsOneWidget);
    expect(find.text('Pi B'), findsOneWidget);
    expect(find.text('Total queries: 150'), findsOneWidget);
    // Only the successful server has a dated snapshot. The failure card must
    // never imply that its previous content is current.
    expect(find.textContaining('Snapshot captured:'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.text('Could not retrieve statistics. Other servers are unaffected.'), findsOneWidget);
  });

  testWidgets('stale snapshot stays dated and visible on refresh failure', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final gate = Completer<ServerOverviewMetrics>();
    var reads = 0;
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
            ],
            reader: (_) {
              reads++;
              if (reads == 1) {
                return Future.value(const ServerOverviewMetrics(
                  queries: 150, blocked: 30, blockedPercentage: 20,
                ));
              }
              return gate.future;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Total queries: 150'), findsNothing);
    await tester.tap(find.text('Refresh all servers'));
    await tester.pumpAndSettle();
    expect(find.text('Total queries: 150'), findsOneWidget);
    expect(find.textContaining('Snapshot captured:'), findsOneWidget);

    await tester.tap(find.text('Refresh all servers'));
    await tester.pump();
    expect(find.text('Total queries: 150'), findsOneWidget);
    expect(find.textContaining('Snapshot captured:'), findsOneWidget);

    gate.completeError(StateError('private SID must not be shown'));
    await tester.pumpAndSettle();
    expect(find.text('Total queries: 150'), findsOneWidget);
    expect(find.textContaining('Snapshot captured:'), findsOneWidget);
    expect(
      find.text('Could not retrieve statistics. Other servers are unaffected.'),
      findsOneWidget,
    );
    expect(find.textContaining('private SID'), findsNothing);
    expect(reads, 2);
  });

}