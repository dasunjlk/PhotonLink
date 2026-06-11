import 'dart:typed_data';

import '../photon_link_core_api.dart';
import '../core_service.dart';
import '../../../transfer/core/integrity_verifier.dart';

/// Dart backend for [CoreService] — delegates to existing implementations.
class DartCoreService implements CoreService {
  const DartCoreService({IntegrityVerifier? verifier})
      : _verifier = verifier ?? const IntegrityVerifier();

  final IntegrityVerifier _verifier;

  @override
  String sha256Hex(Uint8List data) => _verifier.compute(data);

  @override
  bool sha256Verify(Uint8List data, String expectedSha256) =>
      _verifier.verify(data, expectedSha256);

  @override
  int crc32Compute(Uint8List data) => _computeCrc32(data);

  @override
  bool crc32Validate(Uint8List data, int expected) =>
      _computeCrc32(data) == expected;

  /// CRC32 reflected IEEE — matches ColorMatrixSerializer.
  static int _computeCrc32(Uint8List data) {
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc >>= 1;
        }
      }
    }
    return (~crc) & 0xFFFFFFFF;
  }
}

/// Rust backend for [CoreService].
class RustCoreService implements CoreService {
  const RustCoreService(this._api);

  final PhotonLinkCoreApi _api;

  @override
  String sha256Hex(Uint8List data) => _api.sha256Hex(data);

  @override
  bool sha256Verify(Uint8List data, String expectedSha256) =>
      _api.sha256Verify(data, expectedSha256);

  @override
  int crc32Compute(Uint8List data) => _api.crc32Compute(data);

  @override
  bool crc32Validate(Uint8List data, int expected) =>
      _api.crc32Validate(data, expected);
}
