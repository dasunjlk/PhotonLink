import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/app_exceptions.dart';
import '../logger/app_logger.dart';

/// Handles runtime permission requests for camera and storage.
class PermissionService {
  /// Requests camera permission. Returns true if granted.
  Future<bool> requestCamera() async {
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

  /// Ensures camera permission is granted, throws if denied.
  Future<void> ensureCamera() async {
    // Web browsers prompt via getUserMedia when the camera plugin initializes.
    if (kIsWeb) return;

    final granted = await requestCamera();
    if (!granted) {
      throw const PermissionDeniedException(
        'Camera permission is required for optical scanning.',
      );
    }
  }

  /// Opens the system app settings page.
  Future<bool> openSettings() => openAppSettings();
}
