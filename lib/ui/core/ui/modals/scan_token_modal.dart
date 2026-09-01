import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';
import 'package:zxing2/qrcode.dart';

typedef ScanTokenScannerBuilder = Widget Function(ValueChanged<String> onScanned);

Widget _buildQrScanner(ValueChanged<String> onScanned) {
  return _CameraQrScanner(onScanned: onScanned);
}

Future<void> showScanTokenModal(
  BuildContext context,
  Function(String) onScanned, {
  ScanTokenScannerBuilder scannerBuilder = _buildQrScanner,
}) async {
  await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return ScanTokenModal(
        qrScanned: onScanned,
        scannerBuilder: scannerBuilder,
      );
    },
  );
}

class ScanTokenModal extends StatelessWidget {
  const ScanTokenModal({
    super.key,
    required this.qrScanned,
    this.scannerBuilder = _buildQrScanner,
  });

  final Function(String) qrScanned;
  final ScanTokenScannerBuilder scannerBuilder;

  @override
  Widget build(BuildContext context) {
    return _ScanTokenDialog(
      onScanned: qrScanned,
      scannerBuilder: scannerBuilder,
    );
  }
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

class _CameraQrScanner extends StatefulWidget {
  const _CameraQrScanner({required this.onScanned});

  final ValueChanged<String> onScanned;

  @override
  State<_CameraQrScanner> createState() => _CameraQrScannerState();
}

class _CameraQrScannerState extends State<_CameraQrScanner> {
  final QRCodeReader _reader = QRCodeReader();

  CameraController? _controller;
  Object? _initializationError;
  bool _processingFrame = false;
  bool _scanCompleted = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeCamera());
  }

  Future<void> _initializeCamera() async {
    CameraController? controller;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no-camera', 'No camera is available.');
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
      });
      await controller.startImageStream(_processCameraImage);
    } on Object catch (error) {
      await controller?.dispose();
      if (!mounted) return;

      setState(() {
        _controller = null;
        _initializationError = error;
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_processingFrame || _scanCompleted) return;
    _processingFrame = true;

    try {
      final source = _createLuminanceSource(image);
      if (source == null) return;

      final bitmap = BinaryBitmap(HybridBinarizer(source));
      final result = _reader.decode(bitmap);
      if (result.text.isEmpty) return;

      _scanCompleted = true;
      final controller = _controller;
      if (controller != null && controller.value.isStreamingImages) {
        try {
          await controller.stopImageStream();
        } on CameraException {
          // The dialog may already be closing. The successful scan still wins.
        }
      }

      if (mounted) {
        widget.onScanned(result.text);
      }
    } on ReaderException {
      // No decodable QR code in this frame. Keep scanning.
    } finally {
      _processingFrame = false;
    }
  }

  LuminanceSource? _createLuminanceSource(CameraImage image) {
    if (image.planes.isEmpty || image.width <= 0 || image.height <= 0) {
      return null;
    }

    final plane = image.planes.first;
    final width = image.width;
    final height = image.height;
    final pixelCount = width * height;
    final bytes = plane.bytes;
    final rowStride = plane.bytesPerRow;

    if (rowStride < width) return null;

    if (rowStride == width && bytes.length >= pixelCount) {
      return _YPlaneLuminanceSource(
        Int8List.view(bytes.buffer, bytes.offsetInBytes, pixelCount),
        width,
        height,
      );
    }

    final compact = Uint8List(pixelCount);
    for (var row = 0; row < height; row++) {
      final sourceOffset = row * rowStride;
      if (sourceOffset + width > bytes.length) return null;
      final targetOffset = row * width;
      compact.setRange(
        targetOffset,
        targetOffset + width,
        bytes,
        sourceOffset,
      );
    }

    return _YPlaneLuminanceSource(
      Int8List.view(compact.buffer),
      width,
      height,
    );
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_initializationError != null) {
      return const Center(child: Icon(Icons.no_photography_outlined, size: 48));
    }

    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return CameraPreview(controller);
  }
}

class _YPlaneLuminanceSource extends LuminanceSource {
  _YPlaneLuminanceSource(this._luminances, int width, int height)
    : super(width, height);

  final Int8List _luminances;

  @override
  Int8List getMatrix() => _luminances;

  @override
  Int8List getRow(int y, Int8List? row) {
    if (y < 0 || y >= height) {
      throw RangeError.range(y, 0, height - 1, 'y');
    }

    final target = row != null && row.length >= width
        ? row
        : Int8List(width);
    final offset = y * width;
    target.setRange(0, width, _luminances, offset);
    return target;
  }
}
