import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/ui/core/ui/components/auto_complate_field.dart';

void main() {
  testWidgets(
    'mouse tap on a suggestion selects it without premature focus loss',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: AutoCompleteField<String>(
                  items: const ['192.168.1.10', '192.168.1.20'],
                  controller: controller,
                  onChanged: (_) {},
                  textOf: (item) => item,
                  labelText: 'IP Address',
                  isAnimated: false,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byType(TextField),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(find.text('192.168.1.10'), findsOneWidget);

      await tester.tap(
        find.text('192.168.1.10'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(controller.text, '192.168.1.10');
      expect(find.text('192.168.1.20'), findsNothing);
    },
  );

  testWidgets('mouse tap outside still dismisses suggestions', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                width: 400,
                child: AutoCompleteField<String>(
                  items: const ['192.168.1.10', '192.168.1.20'],
                  controller: controller,
                  onChanged: (_) {},
                  textOf: (item) => item,
                  labelText: 'IP Address',
                  isAnimated: false,
                ),
              ),
              const TextButton(onPressed: null, child: Text('Outside')),
            ],
          ),
        ),
      ),
    );

    await tester.tap(
      find.byType(TextField),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(find.text('192.168.1.10'), findsOneWidget);

    await tester.tap(find.text('Outside'), kind: PointerDeviceKind.mouse);
    await tester.pump();

    expect(find.text('192.168.1.10'), findsNothing);
  });
}
