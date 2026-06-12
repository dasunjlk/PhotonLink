import 'package:camera/camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/errors/app_exceptions.dart';

/// Human-readable camera and scanner error text for UI surfaces.
String describeCameraFailure(Object error) {
  if (error is PermissionDeniedException) {
    return error.message;
  }

  if (error is CameraUnavailableException) {
    return error.message;
  }

  if (error is CameraException) {
    return switch (error.code) {
      'CameraAccessDenied' =>
        'Camera access was denied. Allow camera access in system or browser settings, then retry.',
      'CameraAccessDeniedWithoutPrompt' =>
        'Camera access is blocked. Open Settings and enable camera access for PhotonLink.',
      'CameraAccessRestricted' => 'Camera access is restricted on this device.',
      'AudioAccessDenied' ||
      'AudioAccessDeniedWithoutPrompt' =>
        'Microphone access was denied.',
      'noCamera' => error.description ?? 'No camera found on this device.',
      _ => error.description?.isNotEmpty == true
          ? error.description!
          : 'Could not start the camera (${error.code}).',
    };
  }

  if (error is MobileScannerException) {
    return describeMobileScannerFailure(error);
  }

  final text = error.toString();
  if (text.contains('NotAllowedError') || text.contains('Permission denied')) {
    return 'Camera access was denied. Allow camera access in your browser or system settings, then retry.';
  }

  return 'Could not start the camera. $text';
}

String describeMobileScannerFailure(MobileScannerException error) {
  return switch (error.errorCode) {
    MobileScannerErrorCode.permissionDenied =>
      'Camera access was denied. Allow camera access in your browser or system settings, then retry.',
    MobileScannerErrorCode.unsupported =>
      'QR camera scanning is not supported on this device. Use the web or mobile app.',
    MobileScannerErrorCode.controllerNotAttached =>
      'Camera preview is still starting. Wait a moment and retry.',
    _ => error.errorDetails?.message ?? error.errorCode.message,
  };
}
