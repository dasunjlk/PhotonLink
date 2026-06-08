import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'key_exchange.dart';

/// Simplified random session key in setup QR (replace with X25519 later).
class SessionKeyExchange implements KeyExchange {
  SessionKeyExchange({Random? random}) : _random = random ?? Random.secure();

  final Random _random;
  static const int keyLength = 32;

  @override
  Future<KeyExchangeResult> generateForSender() async {
    final key = Uint8List(keyLength);
    for (var i = 0; i < keyLength; i++) {
      key[i] = _random.nextInt(256);
    }
    return KeyExchangeResult(
      sessionKey: key,
      payloadBase64: base64Encode(key),
    );
  }

  @override
  Future<Uint8List> acceptFromReceiver(String keyExchangePayloadBase64) async {
    final decoded = base64Decode(keyExchangePayloadBase64);
    if (decoded.length != keyLength) {
      throw FormatException('Invalid session key length');
    }
    return Uint8List.fromList(decoded);
  }
}
