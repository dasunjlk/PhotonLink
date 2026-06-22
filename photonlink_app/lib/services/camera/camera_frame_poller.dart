import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

import 'camera_platform.dart';

typedef RgbFrameCallback = void Function({
  required Uint8List bytes,
  required int width,
  required int height,
});

/// Periodically captures still frames when [CameraController.startImageStream]
/// is unavailable (e.g. Windows desktop).
class CameraFramePoller {
  CameraFramePoller({
    required this.controller,
    required this.intervalMs,
    required this.onFrame,
  });

  final CameraController controller;
  final int intervalMs;
  final RgbFrameCallback onFrame;

  Timer? _timer;
  bool _busy = false;

  bool get isActive => _timer != null;

  void start() {
    _timer ??= Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => unawaited(_capture()),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _capture() async {
    if (_busy || !controller.value.isInitialized) return;
    _busy = true;
    try {
      final capture = await controller.takePicture();
      final bytes = await File(capture.path).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return;
      final rgb = decodedImageToRgb(image);
      onFrame(bytes: rgb.bytes, width: rgb.width, height: rgb.height);
    } catch (_) {
      // Skip failed captures; UI retry handles persistent failures.
    } finally {
      _busy = false;
    }
  }
}
