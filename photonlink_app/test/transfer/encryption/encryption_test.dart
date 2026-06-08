import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/encryption_mode.dart';
import 'package:photonlink_app/transfer/encryption/encryption_manager.dart';
import 'package:photonlink_app/transfer/encryption/models/encrypted_payload.dart';
import 'package:photonlink_app/transfer/encryption/chacha20_encryption_strategy.dart';

void main() {
  final key = Uint8List.fromList(List.generate(32, (i) => i));
  final manager = EncryptionManager();
  final strategy = ChaCha20EncryptionStrategy();

  test('encrypt decrypt roundtrip', () async {
    final plain = Uint8List.fromList(List.generate(200, (i) => i % 256));
    final enc = await manager.encryptIfEnabled(
      plaintext: plain,
      sessionKey: key,
      mode: EncryptionMode.enabled,
    );
    expect(enc.length, greaterThan(plain.length));
    final dec = await manager.decryptIfEnabled(
      wireBytes: enc,
      sessionKey: key,
      mode: EncryptionMode.enabled,
    );
    expect(dec, plain);
  });

  test('corrupted ciphertext fails', () async {
    final plain = Uint8List.fromList([1, 2, 3, 4]);
    final enc = await strategy.encrypt(plain, key);
    final wire = enc.toWireBytes();
    wire[wire.length - 1] ^= 0xff;
    expect(
      () => strategy.decrypt(EncryptedPayload.fromWireBytes(wire), key),
      throwsA(isA<Exception>()),
    );
  });

  test('disabled passes through', () async {
    final plain = Uint8List.fromList([9, 8, 7]);
    final out = await manager.encryptIfEnabled(
      plaintext: plain,
      sessionKey: key,
      mode: EncryptionMode.disabled,
    );
    expect(out, plain);
  });
}
