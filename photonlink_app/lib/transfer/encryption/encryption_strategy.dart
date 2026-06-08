import 'dart:typed_data';

import '../../protocols/interfaces/encryption_mode.dart';

/// Result of encrypting a payload.
class EncryptedPayload {
  const EncryptedPayload({
    required this.ciphertext,
    required this.nonce,
    required this.salt,
  });

  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List salt;
}

/// Encrypts and decrypts file payloads before chunking.
abstract interface class EncryptionStrategy {
  EncryptionMode get mode;
  EncryptedPayload encrypt({
    required Uint8List plaintext,
    required String passphrase,
    Uint8List? salt,
  });
  Uint8List decrypt({
    required EncryptedPayload payload,
    required String passphrase,
  });
}
