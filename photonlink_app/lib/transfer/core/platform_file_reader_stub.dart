import 'dart:typed_data';

/// Web: only in-memory bytes are available from [FilePicker].
Future<Uint8List> loadFileBytes({
  Uint8List? fileBytes,
  String? filePath,
}) async {
  if (fileBytes != null && fileBytes.isNotEmpty) {
    return fileBytes;
  }
  throw StateError(
    'On web, file bytes must be provided (path is unavailable)',
  );
}
