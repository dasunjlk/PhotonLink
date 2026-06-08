import 'dart:typed_data';

/// Future-ready key exchange abstraction (Phase 4: simplified setup packet).
abstract interface class KeyExchange {
  /// Generates session key material for the sender.
  Future<KeyExchangeResult> generateForSender();

  /// Receiver parses key material from setup payload.
  Future<Uint8List> acceptFromReceiver(String keyExchangePayloadBase64);
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
