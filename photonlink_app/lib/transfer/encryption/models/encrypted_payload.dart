import 'dart:typed_data';

/// Ciphertext with nonce for AEAD decryption.
class EncryptedPayload {
  const EncryptedPayload({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
  });

  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List mac;

  Uint8List toWireBytes() {
    final out = BytesBuilder();
    out.add(nonce);
    out.add(mac);
    out.add(ciphertext);
    return out.toBytes();
  }

  static EncryptedPayload fromWireBytes(Uint8List wire) {
    if (wire.length < 28) {
      throw FormatException('Encrypted payload too short');
    }
    return EncryptedPayload(
      nonce: Uint8List.fromList(wire.sublist(0, 12)),
      mac: Uint8List.fromList(wire.sublist(12, 28)),
      ciphertext: Uint8List.fromList(wire.sublist(28)),
    );
  }
}
