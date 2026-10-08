import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/gravity/gravity_stream_diagnostics.dart';
import 'package:pi_hole_client/ui/settings/server_settings/adlists/widgets/gravity_stream_hint_card.dart';

import '../../../../../../testing/test_app.dart';

void main() async {
  await initTestApp();

  testWidgets('displays actionable but conditional nginx hint', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const Scaffold(
          body: GravityStreamHintCard(
            hint: GravityStreamHint.possibleProxyBuffering,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Possible reverse-proxy buffering'), findsOneWidget);
    expect(find.textContaining('proxy_buffering off;'), findsOneWidget);
    expect(find.textContaining('/api/action/gravity'), findsOneWidget);
    expect(find.textContaining('other causes'), findsOneWidget);
  });
}
