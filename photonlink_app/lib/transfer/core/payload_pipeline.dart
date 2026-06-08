import 'dart:typed_data';

import '../../core/constants.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../compression/compression_manager.dart';
import '../encryption/encryption_manager.dart';
import '../security/encryption_key_provider.dart';
import 'integrity_verifier.dart';

/// Pre-chunk transform: compress → encrypt → hash (transport-agnostic).
class PayloadPipeline {
  PayloadPipeline({
    CompressionManager? compressionManager,
    EncryptionManager? encryptionManager,
    IntegrityVerifier? integrityVerifier,
  })  : _compression = compressionManager ?? CompressionManager(),
        _encryption = encryptionManager ?? EncryptionManager(),
        _verifier = integrityVerifier ?? const IntegrityVerifier();

  final CompressionManager _compression;
  final EncryptionManager _encryption;
  final IntegrityVerifier _verifier;

  /// Result of preparing wire bytes for chunking.
  Future<PayloadPrepareResult> prepareForSend({
    required Uint8List fileBytes,
    required CompressionType compression,
    required EncryptionMode encryption,
    required EncryptionKeyProvider keyProvider,
  }) async {
    final originalSha256 = _verifier.compute(fileBytes);
    final originalSize = fileBytes.length;

    var bytes = fileBytes;
    CompressionType usedCompression = CompressionType.none;
    if (compression != CompressionType.none) {
      final result = _compression.compress(bytes, compression);
      bytes = Uint8List.fromList(result.bytes);
      usedCompression = compression;
    }

    var encryptionOverhead = 0;
    if (encryption == EncryptionMode.enabled) {
      if (!keyProvider.hasKey) {
        throw StateError('Session key required for encryption');
      }
      final before = bytes.length;
      bytes = await _encryption.encryptIfEnabled(
        plaintext: bytes,
        sessionKey: keyProvider.sessionKey,
        mode: encryption,
      );
      encryptionOverhead = bytes.length - before;
    }

    final wireSha256 = _verifier.compute(bytes);

    return PayloadPrepareResult(
      wireBytes: bytes,
      originalSize: originalSize,
      originalSha256: originalSha256,
      wireSha256: wireSha256,
      compression: usedCompression,
      encryption: encryption,
      encryptionOverheadBytes: encryptionOverhead,
      compressionRatio:
          originalSize > 0 ? bytes.length / originalSize : 1.0,
      protocolVersion: AppConstants.protocolVersion,
    );
  }

  /// Inverse after reconstruction: decrypt → decompress.
  Future<Uint8List> restorePlaintext({
    required Uint8List wireBytes,
    required MetadataPacketFields meta,
    required EncryptionKeyProvider keyProvider,
  }) async {
    var bytes = wireBytes;
    if (meta.encryption == EncryptionMode.enabled) {
      if (!keyProvider.hasKey) {
        throw StateError('Session key required for decryption');
      }
      bytes = await _encryption.decryptIfEnabled(
        wireBytes: bytes,
        sessionKey: keyProvider.sessionKey,
        mode: meta.encryption,
      );
    }

    if (meta.compression != CompressionType.none) {
      final originalSize = meta.originalSize ?? bytes.length;
      final result = _compression.decompress(
        bytes,
        type: meta.compression,
        originalSize: originalSize,
      );
      bytes = Uint8List.fromList(result.bytes);
    }

    return bytes;
  }
}

/// Metadata fields needed for restore (avoids circular import with packet).
class MetadataPacketFields {
  const MetadataPacketFields({
    required this.compression,
    required this.encryption,
    this.originalSize,
    this.originalSha256,
  });

  final CompressionType compression;
  final EncryptionMode encryption;
  final int? originalSize;
  final String? originalSha256;
}

class PayloadPrepareResult {
  const PayloadPrepareResult({
    required this.wireBytes,
    required this.originalSize,
    required this.originalSha256,
    required this.wireSha256,
    required this.compression,
    required this.encryption,
    required this.encryptionOverheadBytes,
    required this.compressionRatio,
    required this.protocolVersion,
  });

  final Uint8List wireBytes;
  final int originalSize;
  final String originalSha256;
  final String wireSha256;
  final CompressionType compression;
  final EncryptionMode encryption;
  final int encryptionOverheadBytes;
  final double compressionRatio;
  final int protocolVersion;
}
