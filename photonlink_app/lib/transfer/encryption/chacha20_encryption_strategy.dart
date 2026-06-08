import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../protocols/interfaces/encryption_mode.dart';
import 'encryption_strategy.dart';

/// ChaCha20-Poly1305 encryption with PBKDF2 key derivation.
class ChaCha20EncryptionStrategy implements EncryptionStrategy {
  ChaCha20EncryptionStrategy({Chacha20? algorithm})
      : _algorithm = algorithm ?? Chacha20.poly1305Aead();

  final Cipher _algorithm;

  static const int saltLength = 16;
  static const int nonceLength = 12;
  static const int pbkdf2Iterations = 100000;

  @override
  EncryptionMode get mode => EncryptionMode.chacha20Poly1305;

  Future<EncryptedPayload> encryptAsync({
    required Uint8List plaintext,
    required String passphrase,
    Uint8List? salt,
  }) async {
    final resolvedSalt = salt ?? _randomBytes(saltLength);
    final nonce = _randomBytes(nonceLength);
    final secretKey = await _deriveKey(passphrase, resolvedSalt);
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );
    return EncryptedPayload(
      ciphertext: Uint8List.fromList(
        secretBox.cipherText + secretBox.mac.bytes,
      ),
      nonce: nonce,
      salt: resolvedSalt,
    );
  }

  Future<Uint8List> decryptAsync({
    required EncryptedPayload payload,
    required String passphrase,
  }) async {
    if (payload.ciphertext.length < 16) {
      throw StateError('Ciphertext too short');
    }
    final secretKey = await _deriveKey(passphrase, payload.salt);
    const macLength = 16;
    final cipherLen = payload.ciphertext.length - macLength;
    final cipherText = payload.ciphertext.sublist(0, cipherLen);
    final mac = Mac(payload.ciphertext.sublist(cipherLen));
    final secretBox = SecretBox(cipherText, nonce: payload.nonce, mac: mac);
    return Uint8List.fromList(
      await _algorithm.decrypt(secretBox, secretKey: secretKey),
    );
  }

  @override
  EncryptedPayload encrypt({
    required Uint8List plaintext,
    required String passphrase,
    Uint8List? salt,
  }) {
    throw UnsupportedError('Use encryptAsync for ChaCha20');
  }

  @override
  Uint8List decrypt({
    required EncryptedPayload payload,
    required String passphrase,
  }) {
    throw UnsupportedError('Use decryptAsync for ChaCha20');
  }

  Future<SecretKey> _deriveKey(String passphrase, Uint8List salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: pbkdf2Iterations,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }
}
