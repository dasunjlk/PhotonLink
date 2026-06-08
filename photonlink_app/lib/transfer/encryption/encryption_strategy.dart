import 'dart:typed_data';

import '../../protocols/interfaces/encryption_mode.dart';
import 'models/encrypted_payload.dart';

/// Transport-agnostic encryption codec.
abstract interface class EncryptionStrategy {
  EncryptionMode get mode;

  Future<EncryptedPayload> encrypt(Uint8List plaintext, Uint8List sessionKey);

  Future<Uint8List> decrypt(
    EncryptedPayload payload,
    Uint8List sessionKey,
  );
}
