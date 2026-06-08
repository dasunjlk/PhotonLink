import 'dart:typed_data';

import '../../protocols/interfaces/encryption_mode.dart';
import 'chacha20_encryption_strategy.dart';
import 'encryption_strategy.dart';
import 'models/encrypted_payload.dart';

/// Applies optional ChaCha20-Poly1305 encryption (transport-agnostic).
class EncryptionManager {
  EncryptionManager({EncryptionStrategy? enabled})
      : _enabled = enabled ?? ChaCha20EncryptionStrategy();

  final EncryptionStrategy _enabled;

  Future<Uint8List> encryptIfEnabled({
    required Uint8List plaintext,
    required Uint8List sessionKey,
    required EncryptionMode mode,
  }) async {
    if (mode == EncryptionMode.disabled) return plaintext;
    final enc = await _enabled.encrypt(plaintext, sessionKey);
    return enc.toWireBytes();
  }

  Future<Uint8List> decryptIfEnabled({
    required Uint8List wireBytes,
    required Uint8List sessionKey,
    required EncryptionMode mode,
  }) async {
    if (mode == EncryptionMode.disabled) return wireBytes;
    final payload = EncryptedPayload.fromWireBytes(wireBytes);
    return _enabled.decrypt(payload, sessionKey);
  }
}
