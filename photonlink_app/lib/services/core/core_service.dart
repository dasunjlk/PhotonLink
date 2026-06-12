import 'dart:typed_data';

/// Hashing and checksum validation (Phase 8A).
abstract interface class CoreService {
  String sha256Hex(Uint8List data);
  bool sha256Verify(Uint8List data, String expectedSha256);
  int crc32Compute(Uint8List data);
  bool crc32Validate(Uint8List data, int expected);
}
