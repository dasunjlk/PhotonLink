import 'dart:typed_data';

import '../../protocols/interfaces/encryption_mode.dart';

/// Encryption operations (Phase 8B).
abstract interface class EncryptionService {
  Future<Uint8List> encryptIfEnabled({
    required Uint8List plaintext,
    required Uint8List sessionKey,
    required EncryptionMode mode,
  });

  Future<Uint8List> decryptIfEnabled({
    required Uint8List wireBytes,
    required Uint8List sessionKey,
    required EncryptionMode mode,
  });
}
