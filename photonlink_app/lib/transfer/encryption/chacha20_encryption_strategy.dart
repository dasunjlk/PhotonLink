import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../core/constants.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import 'encryption_strategy.dart';
import 'models/encrypted_packet_metadata.dart';
import 'models/encrypted_payload.dart';

/// ChaCha20-Poly1305 AEAD via the cryptography package.
class ChaCha20EncryptionStrategy implements EncryptionStrategy {
  ChaCha20EncryptionStrategy() : _algorithm = Chacha20.poly1305Aead();

  final Cipher _algorithm;

  @override
  EncryptionMode get mode => EncryptionMode.enabled;

  @override
  Future<EncryptedPayload> encrypt(
    Uint8List plaintext,
    Uint8List sessionKey,
  ) async {
    final secretKey = SecretKey(sessionKey);
    final nonce = _algorithm.newNonce();
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );
    return EncryptedPayload(
      nonce: Uint8List.fromList(nonce),
      mac: Uint8List.fromList(secretBox.mac.bytes),
      ciphertext: Uint8List.fromList(secretBox.cipherText),
    );
  }

  @override
  Future<Uint8List> decrypt(
    EncryptedPayload payload,
    Uint8List sessionKey,
  ) async {
    final secretKey = SecretKey(sessionKey);
    final secretBox = SecretBox(
      payload.ciphertext,
      nonce: payload.nonce,
      mac: Mac(payload.mac),
    );
    final plain = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    return Uint8List.fromList(plain);
  }

  EncryptedPacketMetadata metadata() => EncryptedPacketMetadata(
        mode: mode,
        protocolVersion: AppConstants.protocolVersion,
      );
}
