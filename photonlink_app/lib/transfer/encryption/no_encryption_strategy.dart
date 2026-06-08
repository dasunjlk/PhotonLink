import 'dart:typed_data';

import '../../protocols/interfaces/encryption_mode.dart';
import 'encryption_strategy.dart';
import 'models/encrypted_payload.dart';

/// Pass-through encryption (no-op).
class NoEncryptionStrategy implements EncryptionStrategy {
  const NoEncryptionStrategy();

  @override
  EncryptionMode get mode => EncryptionMode.disabled;

  @override
  Future<EncryptedPayload> encrypt(
    Uint8List plaintext,
    Uint8List sessionKey,
  ) async {
    return EncryptedPayload(
      ciphertext: plaintext,
      nonce: Uint8List(0),
      mac: Uint8List(0),
    );
  }

  @override
  Future<Uint8List> decrypt(
    EncryptedPayload payload,
    Uint8List sessionKey,
  ) async {
    return payload.ciphertext;
  }
}
