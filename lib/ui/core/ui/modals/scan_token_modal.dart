import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';

typedef ScanTokenScannerBuilder = Widget Function(ValueChanged<String> onScanned);

Widget _buildMobileScanner(ValueChanged<String> onScanned) {
  return MobileScanner(
    onDetect: (barcodeCapture) {
      if (barcodeCapture.barcodes.isNotEmpty) {
        onScanned(barcodeCapture.barcodes[0].displayValue ?? '');
      }
    },
  );
}

Future<void> showScanTokenModal(
  BuildContext context,
  Function(String) onScanned, {
  ScanTokenScannerBuilder scannerBuilder = _buildMobileScanner,
}) async {
  await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return _ScanTokenDialog(
        onScanned: onScanned,
        scannerBuilder: scannerBuilder,
      );
    },
  );
}

class _ScanTokenDialog extends StatelessWidget {
  const _ScanTokenDialog({
    required this.onScanned,
    required this.scannerBuilder,
  });

  final Function(String) onScanned;
  final ScanTokenScannerBuilder scannerBuilder;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    void handleScanned(String token) {
      navigator.pop();
      onScanned(token);
    }

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.scanQrCode),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 250,
          width: 250,
          child: scannerBuilder(handleScanned),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
      ],
    );
  }
}
