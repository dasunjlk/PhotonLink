import 'dart:typed_data';

import '../../protocols/interfaces/encryption_mode.dart';
import 'chacha20_encryption_strategy.dart';
import 'encryption_strategy.dart';
import 'no_encryption_strategy.dart';

/// Selects and applies encryption strategies.
class EncryptionManager {
  EncryptionManager({
    NoEncryptionStrategy? none,
    ChaCha20EncryptionStrategy? chacha20,
  })  : _none = none ?? const NoEncryptionStrategy(),
        _chacha20 = chacha20 ?? ChaCha20EncryptionStrategy();

  final NoEncryptionStrategy _none;
  final ChaCha20EncryptionStrategy _chacha20;

  EncryptionStrategy strategyFor(EncryptionMode mode) {
    switch (mode) {
      case EncryptionMode.none:
        return _none;
      case EncryptionMode.chacha20Poly1305:
        return _chacha20;
    }
  }

  Future<EncryptedPayload> encrypt({
    required EncryptionMode mode,
    required Uint8List plaintext,
    required String passphrase,
    Uint8List? salt,
  }) async {
    switch (mode) {
      case EncryptionMode.none:
        return _none.encrypt(
          plaintext: plaintext,
          passphrase: passphrase,
          salt: salt,
        );
      case EncryptionMode.chacha20Poly1305:
        return _chacha20.encryptAsync(
          plaintext: plaintext,
          passphrase: passphrase,
          salt: salt,
        );
    }
  }

  Future<Uint8List> decrypt({
    required EncryptionMode mode,
    required EncryptedPayload payload,
    required String passphrase,
  }) async {
    switch (mode) {
      case EncryptionMode.none:
        return _none.decrypt(payload: payload, passphrase: passphrase);
      case EncryptionMode.chacha20Poly1305:
        return _chacha20.decryptAsync(
          payload: payload,
          passphrase: passphrase,
        );
    }
  }
}
