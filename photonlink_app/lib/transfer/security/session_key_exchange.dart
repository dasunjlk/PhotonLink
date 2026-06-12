import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

import 'key_exchange.dart';

/// Ephemeral X25519 key exchange with wrapped receiver private material.
///
/// The session key is derived via ECDH without transmitting raw key bytes.
/// Receiver private bytes are wrapped with a key derived from public fields.
class SessionKeyExchange implements KeyExchange {
  SessionKeyExchange() : _algorithm = X25519();

  final X25519 _algorithm;
  final Cipher _cipher = Chacha20.poly1305Aead();
  static const int keyLength = 32;

  @override
  Future<KeyExchangeResult> generateForSender({String sessionId = ''}) async {
    final senderKeyPair = await _algorithm.newKeyPair();
    final receiverKeyPair = await _algorithm.newKeyPair();

    final sharedSecret = await _algorithm.sharedSecretKey(
      keyPair: senderKeyPair,
      remotePublicKey: await receiverKeyPair.extractPublicKey(),
    );
    final keyBytes = await sharedSecret.extractBytes();
    final sessionKey = Uint8List.fromList(keyBytes.take(keyLength).toList());

    final senderPub = (await senderKeyPair.extractPublicKey()).bytes;
    final receiverPub = (await receiverKeyPair.extractPublicKey()).bytes;
    final receiverPriv = await receiverKeyPair.extractPrivateKeyBytes();

    final wrapKey = await _deriveWrapKey(
      senderPublicKey: senderPub,
      receiverPublicKey: receiverPub,
      sessionId: sessionId,
    );
    final secretBox = await _cipher.encrypt(
      receiverPriv,
      secretKey: wrapKey,
      nonce: _nonceForSession(sessionId),
    );
    final wrappedReceiverPriv = secretBox.cipherText + secretBox.mac.bytes;

    final payload = jsonEncode({
      'v': 2,
      'spk': base64Encode(senderPub),
      'rpk': base64Encode(receiverPub),
      'wrp': base64Encode(wrappedReceiverPriv),
    });

    return KeyExchangeResult(
      sessionKey: sessionKey,
      payloadBase64: base64Encode(utf8.encode(payload)),
    );
  }

  @override
  Future<Uint8List> acceptFromReceiver(
    String keyExchangePayloadBase64, {
    String sessionId = '',
  }) async {
    final decoded = base64Decode(keyExchangePayloadBase64);
    final jsonMap = jsonDecode(utf8.decode(decoded)) as Map<String, dynamic>;
    final version = jsonMap['v'] as int? ?? 0;
    if (version != 2) {
      throw FormatException('Unsupported key exchange version: $version');
    }

    final senderPub = base64Decode(jsonMap['spk'] as String);
    final receiverPub = base64Decode(jsonMap['rpk'] as String);
    final wrapped = base64Decode(jsonMap['wrp'] as String);
    if (wrapped.length < 16) {
      throw FormatException('Invalid wrapped receiver private key');
    }

    final wrapKey = await _deriveWrapKey(
      senderPublicKey: senderPub,
      receiverPublicKey: receiverPub,
      sessionId: sessionId,
    );
    final mac = Mac(wrapped.sublist(wrapped.length - 16));
    final cipherText = wrapped.sublist(0, wrapped.length - 16);
    final receiverPriv = await _cipher.decrypt(
      SecretBox(
        cipherText,
        nonce: _nonceForSession(sessionId),
        mac: mac,
      ),
      secretKey: wrapKey,
    );

    final receiverKeyPair = await _algorithm.newKeyPairFromSeed(receiverPriv);
    final sharedSecret = await _algorithm.sharedSecretKey(
      keyPair: receiverKeyPair,
      remotePublicKey: SimplePublicKey(
        senderPub,
        type: KeyPairType.x25519,
      ),
    );
    final keyBytes = await sharedSecret.extractBytes();
    return Uint8List.fromList(keyBytes.take(keyLength).toList());
  }

  Future<SecretKey> _deriveWrapKey({
    required List<int> senderPublicKey,
    required List<int> receiverPublicKey,
    required String sessionId,
  }) async {
    final material = <int>[
      ...utf8.encode('photonlink-ke-v2|$sessionId|'),
      ...senderPublicKey,
      ...receiverPublicKey,
    ];
    final digest = await Sha256().hash(material);
    return SecretKey(digest.bytes);
  }

  List<int> _nonceForSession(String sessionId) {
    final seed = utf8.encode('pl-ke-nonce|$sessionId');
    return crypto.sha256.convert(seed).bytes.sublist(0, 12);
  }
}
