import 'dart:io';
import 'dart:typed_data';

/// IO platforms: read from bytes if present, otherwise from disk path.
Future<Uint8List> loadFileBytes({
  Uint8List? fileBytes,
  String? filePath,
}) async {
  if (fileBytes != null && fileBytes.isNotEmpty) {
    return fileBytes;
  }
  if (filePath == null) {
    throw StateError('fileBytes or filePath required');
  }
  return Uint8List.fromList(await File(filePath).readAsBytes());
}
