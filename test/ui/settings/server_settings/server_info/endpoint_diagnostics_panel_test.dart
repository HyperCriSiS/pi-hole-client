import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/server/endpoint_diagnostics.dart';
import 'package:pi_hole_client/ui/settings/server_settings/server_info/widgets/endpoint_diagnostics_panel.dart';

import '../../../../../testing/test_app.dart';

void main() async {
  await initTestApp();

  testWidgets('shows read-only results with sanitized outcome labels', (tester) async {
    var runs = 0;
    await tester.pumpWidget(
      buildTestApp(
        Scaffold(
          body: SingleChildScrollView(
            child: EndpointDiagnosticsPanel(
              running: false,
              onRun: () => runs++,
              checks: const [
                EndpointCheckResult(
                  endpoint: FtlEndpoint.host,
                  outcome: EndpointOutcome.success,
                  elapsed: Duration(milliseconds: 17),
                ),
                EndpointCheckResult(
                  endpoint: FtlEndpoint.system,
                  outcome: EndpointOutcome.authentication,
                  elapsed: Duration(milliseconds: 23),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Individual API endpoints'), findsOneWidget);
    expect(find.text('/api/info/host'), findsOneWidget);
    expect(find.text('Valid (17 ms)'), findsOneWidget);
    expect(find.text('Authentication (23 ms)'), findsOneWidget);
    await tester.tap(find.text('Check endpoints'));
    expect(runs, 1);
  });

  testWidgets('disables duplicate requests while checks run', (tester) async {
    var runs = 0;
    await tester.pumpWidget(
      buildTestApp(
        Scaffold(
          body: EndpointDiagnosticsPanel(
            running: true,
            onRun: () => runs++,
            checks: const [],
          ),
        ),
      ),
    );
    await tester.pump();
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
    expect(runs, 0);
  });
}
