import 'dart:typed_data';

import '../../core/constants.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../services/core/compression_service.dart';
import '../../services/core/core_service.dart';
import '../../services/core/encryption_service.dart';
import '../security/encryption_key_provider.dart';

/// Pre-chunk transform: compress → encrypt → hash (transport-agnostic).
class PayloadPipeline {
  PayloadPipeline({
    CompressionService? compressionService,
    EncryptionService? encryptionService,
    CoreService? coreService,
  })  : _compression = compressionService,
        _encryption = encryptionService,
        _core = coreService;

  final CompressionService? _compression;
  final EncryptionService? _encryption;
  final CoreService? _core;

  /// Convenience wrapper using injected services.
  Future<PayloadPrepareResult> prepare({
    required Uint8List fileBytes,
    required CompressionType compression,
    required EncryptionMode encryption,
    required EncryptionKeyProvider keyProvider,
    bool deferEncryption = false,
  }) async {
    final cs = _compression;
    final es = _encryption;
    final core = _core;
    if (cs == null || es == null || core == null) {
      throw StateError('PayloadPipeline services not configured');
    }

    final originalSha256 = core.sha256Hex(fileBytes);
    final originalSize = fileBytes.length;

    var bytes = fileBytes;
    CompressionType usedCompression = CompressionType.none;
    if (compression != CompressionType.none) {
      final result = cs.compress(bytes, compression);
      bytes = Uint8List.fromList(result.bytes);
      usedCompression = compression;
    }

    var encryptionOverhead = 0;
    final encryptNow =
        encryption == EncryptionMode.enabled && !deferEncryption;
    if (encryptNow) {
      if (!keyProvider.hasKey) {
        throw StateError('Session key required for encryption');
      }
      final before = bytes.length;
      bytes = await es.encryptIfEnabled(
        plaintext: bytes,
        sessionKey: keyProvider.sessionKey,
        mode: encryption,
      );
      encryptionOverhead = bytes.length - before;
    }

    final wireSha256 = core.sha256Hex(bytes);

    return PayloadPrepareResult(
      wireBytes: bytes,
      originalSize: originalSize,
      originalSha256: originalSha256,
      wireSha256: wireSha256,
      compression: usedCompression,
      encryption: encryption,
      encryptionOverheadBytes: encryptionOverhead,
      compressionRatio: originalSize > 0 ? bytes.length / originalSize : 1.0,
      protocolVersion: AppConstants.protocolVersion,
    );
  }

  /// Inverse after reconstruction: decrypt → decompress.
  Future<Uint8List> restore({
    required Uint8List wireBytes,
    required MetadataPacketFields meta,
    required EncryptionKeyProvider keyProvider,
  }) async {
    final cs = _compression;
    final es = _encryption;
    if (cs == null || es == null) {
      throw StateError('PayloadPipeline services not configured');
    }

    var bytes = wireBytes;
    if (meta.encryption == EncryptionMode.enabled) {
      if (!keyProvider.hasKey) {
        throw StateError('Session key required for decryption');
      }
      bytes = await es.decryptIfEnabled(
        wireBytes: bytes,
        sessionKey: keyProvider.sessionKey,
        mode: meta.encryption,
      );
    }

    if (meta.compression != CompressionType.none) {
      final originalSize = meta.originalSize ?? bytes.length;
      final result = cs.decompress(
        bytes,
        type: meta.compression,
        originalSize: originalSize,
      );
      bytes = Uint8List.fromList(result.bytes);
    }

    return bytes;
  }

  /// Encrypts already-compressed wire bytes once the session key is available.
  Future<EncryptedWireResult> encryptWireBytes({
    required Uint8List compressedBytes,
    required EncryptionKeyProvider keyProvider,
  }) async {
    final es = _encryption;
    final core = _core;
    if (es == null || core == null) {
      throw StateError('PayloadPipeline services not configured');
    }
    if (!keyProvider.hasKey) {
      throw StateError('Session key required for encryption');
    }
    final before = compressedBytes.length;
    final encrypted = await es.encryptIfEnabled(
      plaintext: compressedBytes,
      sessionKey: keyProvider.sessionKey,
      mode: EncryptionMode.enabled,
    );
    return EncryptedWireResult(
      wireBytes: encrypted,
      wireSha256: core.sha256Hex(encrypted),
      encryptionOverheadBytes: encrypted.length - before,
    );
  }
}

class EncryptedWireResult {
  const EncryptedWireResult({
    required this.wireBytes,
    required this.wireSha256,
    required this.encryptionOverheadBytes,
  });

  final Uint8List wireBytes;
  final String wireSha256;
  final int encryptionOverheadBytes;
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
