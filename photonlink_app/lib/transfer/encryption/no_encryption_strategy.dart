import 'dart:typed_data';

import '../../protocols/interfaces/encryption_mode.dart';
import 'encryption_strategy.dart';

/// Pass-through encryption (no-op).
class NoEncryptionStrategy implements EncryptionStrategy {
  const NoEncryptionStrategy();

  @override
  EncryptionMode get mode => EncryptionMode.none;

  @override
  EncryptedPayload encrypt({
    required Uint8List plaintext,
    required String passphrase,
    Uint8List? salt,
  }) {
    return EncryptedPayload(
      ciphertext: plaintext,
      nonce: Uint8List(0),
      salt: salt ?? Uint8List(0),
    );
  }

  @override
  Uint8List decrypt({
    required EncryptedPayload payload,
    required String passphrase,
  }) {
    return payload.ciphertext;
  }
}
