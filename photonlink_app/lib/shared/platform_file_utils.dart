import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Whether a picked file can be used for transfer on this platform.
///
/// On web, [PlatformFile.path] must not be read — use [PlatformFile.bytes].
bool isPlatformFileReady(PlatformFile file) {
  if (kIsWeb) {
    return file.bytes != null && file.bytes!.isNotEmpty;
  }
  return file.path != null || (file.bytes != null && file.bytes!.isNotEmpty);
}

/// Disk path when available. Never read [PlatformFile.path] on web.
String? platformFilePath(PlatformFile file) => kIsWeb ? null : file.path;
