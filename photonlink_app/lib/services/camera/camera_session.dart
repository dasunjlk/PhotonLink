import 'package:camera/camera.dart';

import '../../core/errors/app_exceptions.dart';
import '../permissions/permission_service.dart';
import 'camera_platform.dart';

/// Opens the preferred rear (or first available) camera after permission checks.
Future<CameraController> openPreferredCamera({
  required ResolutionPreset preset,
  PermissionService? permissionService,
}) async {
  await (permissionService ?? PermissionService()).ensureCamera();

  final cameras = await availableCameras();
  if (cameras.isEmpty) {
    throw const CameraUnavailableException(
      'No camera found on this device. Connect a webcam and retry.',
    );
  }

  final camera = cameras.firstWhere(
    (c) => c.lensDirection == CameraLensDirection.back,
    orElse: () => cameras.first,
  );

  final controller = createColorMatrixCameraController(camera, preset);
  await controller.initialize();

  if (!controller.value.isInitialized) {
    await controller.dispose();
    throw const CameraUnavailableException(
      'Camera failed to initialize. Close other apps using the camera and retry.',
    );
  }

  return controller;
}
