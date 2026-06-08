import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/qr/qr_frame_codec.dart';

void main() {
  const codec = QrFrameCodec();

  test('NAK roundtrip', () {
    final nak = NakPacket(
      sessionId: 'sess',
      missingPacketIds: [1, 3, 5],
      timestamp: DateTime.utc(2026, 1, 1),
    );
    final decoded = codec.decodeFrame(codec.encodeFrame(nak)) as NakPacket;
    expect(decoded.missingPacketIds, [1, 3, 5]);
  });

  test('Handshake roundtrip', () {
    final hs = HandshakePacket(
      sessionId: 'sess',
      receivedChunkIds: [0, 2],
      timestamp: DateTime.utc(2026, 1, 1),
    );
    final decoded = codec.decodeFrame(codec.encodeFrame(hs)) as HandshakePacket;
    expect(decoded.receivedChunkIds, [0, 2]);
  });

  test('Control roundtrip', () {
    final c = ControlPacket(
      sessionId: 'sess',
      type: ControlType.endOfRound,
      timestamp: DateTime.utc(2026, 1, 1),
    );
    final decoded = codec.decodeFrame(codec.encodeFrame(c)) as ControlPacket;
    expect(decoded.type, ControlType.endOfRound);
  });
}
