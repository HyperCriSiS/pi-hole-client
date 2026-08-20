import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/ui/core/ui/modals/scan_token_modal.dart';

import '../../../../../testing/test_app.dart';

void main() async {
  await initTestApp();

  group('Scan token modal', () {
    testWidgets('forwards a scanned token and closes the dialog', (
      tester,
    ) async {
      String? scannedToken;

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showScanTokenModal(
                context,
                (token) => scannedToken = token,
                scannerBuilder: (onScanned) => TextButton(
                  key: const Key('fake-scanner'),
                  onPressed: () => onScanned('test-token'),
                  child: const Text('Scan result'),
                ),
              ),
              child: const Text('Open scanner'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open scanner'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fake-scanner')), findsOneWidget);

      await tester.tap(find.byKey(const Key('fake-scanner')));
      await tester.pumpAndSettle();

      expect(scannedToken, 'test-token');
      expect(find.byKey(const Key('fake-scanner')), findsNothing);
    });
  });
}
