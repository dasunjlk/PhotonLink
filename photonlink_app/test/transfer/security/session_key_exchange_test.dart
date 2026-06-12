import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/security/session_key_exchange.dart';

void main() {
  test('X25519 key exchange roundtrip derives matching session keys', () async {
    const sessionId = 'pl-test-session-001';
    final exchange = SessionKeyExchange();

    final sender = await exchange.generateForSender(sessionId: sessionId);
    expect(sender.sessionKey.length, SessionKeyExchange.keyLength);

    final receiver = SessionKeyExchange();
    final receiverKey = await receiver.acceptFromReceiver(
      sender.payloadBase64,
      sessionId: sessionId,
    );

    expect(receiverKey, sender.sessionKey);
  });
}
