import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Whether [permission_handler] should gate camera access before opening hardware.
bool usesRuntimeCameraPermission() {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS ||
    TargetPlatform.windows =>
      true,
    _ => false,
  };
}

/// Whether [MobileScanner] can open a live camera preview on this platform.
bool isMobileScannerQrSupported() {
  if (kIsWeb) return true;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS =>
      true,
    _ => false,
  };
}

/// Whether QR scanning is available via any supported backend.
bool isQrCameraScanSupported() =>
    isMobileScannerQrSupported() || usesDesktopQrScanner();

/// Windows/Linux desktop QR uses [CameraController] + ZXing instead of
/// [MobileScanner].
bool usesDesktopQrScanner() {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows || TargetPlatform.linux => true,
    _ => false,
  };
}

/// Whether [CameraController.startImageStream] is expected to work.
bool supportsCameraImageStream() {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows => false,
    _ => true,
  };
}

/// Whether frame analysis should fall back to periodic [takePicture] captures.
bool usesCameraCapturePolling() => !supportsCameraImageStream() && !kIsWeb;

/// Creates a [CameraController] tuned for Color Matrix frame analysis.
CameraController createColorMatrixCameraController(
  CameraDescription camera,
  ResolutionPreset preset,
) {
  if (kIsWeb) {
    return CameraController(camera, preset, enableAudio: false);
  }
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return CameraController(
      camera,
      preset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
  }
  return CameraController(camera, preset, enableAudio: false);
}

/// Converts a [CameraImage] to interleaved RGB bytes.
({Uint8List bytes, int width, int height}) cameraImageToRgb(CameraImage image) {
  switch (image.format.group) {
    case ImageFormatGroup.bgra8888:
      return _bgraToRgb(image);
    case ImageFormatGroup.yuv420:
    case ImageFormatGroup.nv21:
      return _yuv420ToRgb(image);
    default:
      if (image.planes.length >= 3) {
        return _yuv420ToRgb(image);
      }
      if (image.planes.length == 1 && image.planes.first.bytesPerPixel == 4) {
        return _bgraToRgb(image);
      }
      return _yuv420ToRgb(image);
  }
}

({Uint8List bytes, int width, int height}) _bgraToRgb(CameraImage image) {
  final plane = image.planes.first;
  final bytes = plane.bytes;
  final bytesPerRow = plane.bytesPerRow;
  final width = image.width;
  final height = image.height;
  final rgb = Uint8List(width * height * 3);
  var idx = 0;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final offset = y * bytesPerRow + x * 4;
      rgb[idx++] = bytes[offset + 2];
      rgb[idx++] = bytes[offset + 1];
      rgb[idx++] = bytes[offset];
    }
  }

  return (bytes: rgb, width: width, height: height);
}

({Uint8List bytes, int width, int height}) _yuv420ToRgb(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final yPlane = image.planes[0].bytes;
  final uPlane = image.planes.length > 1 ? image.planes[1].bytes : yPlane;
  final vPlane = image.planes.length > 2 ? image.planes[2].bytes : yPlane;
  final rgb = Uint8List(width * height * 3);
  var idx = 0;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final yIndex = y * image.planes[0].bytesPerRow + x;
      final uvIndex = (y ~/ 2) * image.planes[1].bytesPerRow + (x ~/ 2) * 2;

      final yVal = yPlane[yIndex];
      final uVal = uPlane[uvIndex];
      final vVal = vPlane[uvIndex.clamp(0, vPlane.length - 1)];

      final r = yVal + 1.402 * (vVal - 128);
      final g = yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128);
      final b = yVal + 1.772 * (uVal - 128);

      rgb[idx++] = r.round().clamp(0, 255);
      rgb[idx++] = g.round().clamp(0, 255);
      rgb[idx++] = b.round().clamp(0, 255);
    }
  }

  return (bytes: rgb, width: width, height: height);
}

/// Converts a decoded still image to interleaved RGB bytes.
({Uint8List bytes, int width, int height}) decodedImageToRgb(img.Image image) {
  final width = image.width;
  final height = image.height;
  final rgb = Uint8List(width * height * 3);
  var idx = 0;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = image.getPixel(x, y);
      rgb[idx++] = pixel.r.toInt();
      rgb[idx++] = pixel.g.toInt();
      rgb[idx++] = pixel.b.toInt();
    }
  }

  return (bytes: rgb, width: width, height: height);
}

/// Camera preview with desktop-specific mirroring where needed.
Widget buildCameraPreview(CameraController controller) {
  final preview = CameraPreview(controller);
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(-1, 1, 1),
      child: preview,
    );
  }
  return preview;
}
