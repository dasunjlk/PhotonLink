import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/app_exceptions.dart';
import '../camera/camera_platform.dart';
import '../logger/app_logger.dart';

/// Handles runtime permission requests for camera and storage.
class PermissionService {
  /// Requests camera permission. Returns true if granted or not required.
  Future<bool> requestCamera() async {
    if (!usesRuntimeCameraPermission()) return true;

    final status = await Permission.camera.request();
    AppLogger.info('Camera permission: $status');
    return status.isGranted;
  }

  /// Requests storage/media permission appropriate for the platform.
  Future<bool> requestStorage() async {
    final photos = await Permission.photos.request();
    if (photos.isGranted) return true;

    final storage = await Permission.storage.request();
    AppLogger.info('Storage permission: photos=$photos, storage=$storage');
    return storage.isGranted;
  }

  /// Ensures camera permission is granted on platforms that use
  /// [permission_handler]. Web and desktop Windows/Linux rely on the camera
  /// plugin to prompt when hardware is opened.
  Future<void> ensureCamera() async {
    if (!usesRuntimeCameraPermission()) return;

    var status = await Permission.camera.status;
    if (status.isGranted) return;

    status = await Permission.camera.request();
    AppLogger.info('Camera permission: $status');

    if (status.isGranted) return;

    if (status.isPermanentlyDenied) {
      throw const PermissionDeniedException(
        'Camera permission was denied. Open Settings to allow camera access.',
      );
    }

    throw const PermissionDeniedException(
      'Camera permission is required for optical scanning.',
    );
  }

  /// Opens the system app settings page.
  Future<bool> openSettings() => openAppSettings();
}
