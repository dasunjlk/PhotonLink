import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/encryption_mode.dart';
import 'package:photonlink_app/transfer/encryption/encryption_manager.dart';

void main() {
  test('chacha20 encrypt decrypt roundtrip', () async {
    final manager = EncryptionManager();
    final plaintext = Uint8List.fromList(List.generate(256, (i) => i % 256));

    final encrypted = await manager.encrypt(
      mode: EncryptionMode.chacha20Poly1305,
      plaintext: plaintext,
      passphrase: 'test-passphrase',
    );

    final decrypted = await manager.decrypt(
      mode: EncryptionMode.chacha20Poly1305,
      payload: encrypted,
      passphrase: 'test-passphrase',
    );

    expect(decrypted, plaintext);
  });

  test('none encryption is identity', () async {
    final manager = EncryptionManager();
    final data = Uint8List.fromList([1, 2, 3, 4]);

    final encrypted = await manager.encrypt(
      mode: EncryptionMode.none,
      plaintext: data,
      passphrase: '',
    );
    final decrypted = await manager.decrypt(
      mode: EncryptionMode.none,
      payload: encrypted,
      passphrase: '',
    );

    expect(decrypted, data);
  });
}
