import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// SHA-256 integrity verification for transferred files.
class IntegrityVerifier {
  const IntegrityVerifier();

  /// Computes SHA-256 hash as lowercase hex string.
  String compute(Uint8List data) {
    return sha256.convert(data).toString();
  }

  /// Validates data against an expected hex SHA-256 hash.
  bool verify(Uint8List data, String expectedSha256) {
    final actual = compute(data);
    return actual.toLowerCase() == expectedSha256.toLowerCase();
  }

  /// Computes hash from a file path's bytes.
  String computeFromBytes(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }
}

/// MIME type inference from file extension.
String mimeTypeFromExtension(String? extension) {
  switch (extension?.toLowerCase()) {
    case 'txt':
      return 'text/plain';
    case 'pdf':
      return 'application/pdf';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'zip':
      return 'application/zip';
    default:
      return 'application/octet-stream';
  }
}

/// Supported file extensions for Phase 2.
const kSupportedExtensions = ['txt', 'pdf', 'jpg', 'jpeg', 'png', 'zip'];

bool isSupportedExtension(String? extension) {
  if (extension == null) return false;
  return kSupportedExtensions.contains(extension.toLowerCase());
}
