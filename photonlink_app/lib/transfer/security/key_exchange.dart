import 'dart:typed_data';

/// Key exchange abstraction (X25519 ECDH over optical channel).
abstract interface class KeyExchange {
  /// Sender generates ephemeral key material for [sessionId].
  Future<KeyExchangeResult> generateForSender({String sessionId = ''});

  /// Receiver derives the session key from the setup/metadata payload.
  Future<Uint8List> acceptFromReceiver(
    String keyExchangePayloadBase64, {
    String sessionId = '',
  });
}

/// Result of sender-side key generation.
class KeyExchangeResult {
  const KeyExchangeResult({
    required this.sessionKey,
    required this.payloadBase64,
  });

  final Uint8List sessionKey;
  final String payloadBase64;
}
