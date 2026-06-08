import 'dart:typed_data';

import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../compression/compression_manager.dart';
import '../encryption/encryption_manager.dart';
import '../encryption/encryption_strategy.dart';

/// Result of applying forward payload transforms (compress -> encrypt).
class PayloadTransformResult {
  const PayloadTransformResult({
    required this.bytes,
    required this.compression,
    required this.encryption,
    this.kdfSalt,
    this.encryptionNonce,
  });

  final Uint8List bytes;
  final CompressionType compression;
  final EncryptionMode encryption;
  final Uint8List? kdfSalt;
  final Uint8List? encryptionNonce;
}

/// Transport-agnostic compress/encrypt pipeline applied before chunking.
class PayloadPipeline {
  PayloadPipeline({
    CompressionManager? compressionManager,
    EncryptionManager? encryptionManager,
  })  : _compression = compressionManager ?? const CompressionManager(),
        _encryption = encryptionManager ?? EncryptionManager();

  final CompressionManager _compression;
  final EncryptionManager _encryption;

  Future<PayloadTransformResult> forward({
    required Uint8List plaintext,
    required bool compressionEnabled,
    required bool encryptionEnabled,
    required String passphrase,
  }) async {
    var bytes = plaintext;
    final compression = compressionEnabled
        ? CompressionType.gzip
        : CompressionType.none;

    if (compressionEnabled) {
      bytes = _compression.strategyFor(compression).compress(bytes);
    }

    final encryption = encryptionEnabled
        ? EncryptionMode.chacha20Poly1305
        : EncryptionMode.none;

    Uint8List? salt;
    Uint8List? nonce;

    if (encryptionEnabled) {
      final encrypted = await _encryption.encrypt(
        mode: encryption,
        plaintext: bytes,
        passphrase: passphrase,
      );
      bytes = encrypted.ciphertext;
      salt = encrypted.salt;
      nonce = encrypted.nonce;
    }

    return PayloadTransformResult(
      bytes: bytes,
      compression: compression,
      encryption: encryption,
      kdfSalt: salt,
      encryptionNonce: nonce,
    );
  }

  Future<Uint8List> reverse({
    required Uint8List transformed,
    required CompressionType compression,
    required EncryptionMode encryption,
    required String passphrase,
    Uint8List? kdfSalt,
    Uint8List? encryptionNonce,
  }) async {
    var bytes = transformed;

    if (encryption != EncryptionMode.none) {
      bytes = await _encryption.decrypt(
        mode: encryption,
        payload: EncryptedPayload(
          ciphertext: bytes,
          nonce: encryptionNonce ?? Uint8List(0),
          salt: kdfSalt ?? Uint8List(0),
        ),
        passphrase: passphrase,
      );
    }

    if (compression != CompressionType.none) {
      bytes = _compression.strategyFor(compression).decompress(bytes);
    }

    return bytes;
  }
}
