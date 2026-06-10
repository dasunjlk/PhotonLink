import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/compression_type.dart';
import 'package:photonlink_app/protocols/interfaces/encryption_mode.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/qr/qr_frame_codec.dart';

void main() {
  const codec = QrFrameCodec();

  test('session setup roundtrip', () {
    final packet = SessionSetupPacket(
      sessionId: 'sess-setup',
      protocolVersion: 2,
      keyExchangePayload: 'dGVzdA==',
      compression: CompressionType.gzip,
      encryption: EncryptionMode.enabled,
      timestamp: DateTime.utc(2026, 1, 1),
    );
    final frame = codec.encodeFrame(packet);
    expect(frame.contains('|S|'), isTrue);
    final decoded = codec.decodeFrame(frame);
    expect(decoded, isA<SessionSetupPacket>());
  });
}
