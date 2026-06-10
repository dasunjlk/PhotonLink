import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/qr/qr_frame_codec.dart';

void main() {
  const codec = QrFrameCodec();

  test('metadata encode decode roundtrip', () {
    const metadata = MetadataPacket(
      sessionId: 'sess-1',
      fileName: 'notes.txt',
      fileSize: 1024,
      totalChunks: 4,
      sha256:
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      mimeType: 'text/plain',
    );

    final frame = codec.encodeFrame(metadata);
    expect(frame.startsWith('${QrFrameCodec.magic}|M|'), isTrue);

    final decoded = codec.decodeFrame(frame);
    expect(decoded, isA<MetadataPacket>());
    final m = decoded! as MetadataPacket;
    expect(m.sessionId, metadata.sessionId);
    expect(m.fileName, metadata.fileName);
    expect(m.fileSize, metadata.fileSize);
    expect(m.totalChunks, metadata.totalChunks);
    expect(m.sha256, metadata.sha256);
  });

  test('data encode decode roundtrip', () {
    final payload = Uint8List.fromList([0, 127, 255, 42]);
    final packet = DataPacket(
      sessionId: 'sess-2',
      chunkId: 1,
      totalChunks: 3,
      payload: payload,
    );

    final frame = codec.encodeFrame(packet);
    expect(frame.startsWith('${QrFrameCodec.magic}|D|'), isTrue);

    final decoded = codec.decodeFrame(frame) as DataPacket;
    expect(decoded.chunkId, 1);
    expect(decoded.payload, payload);
  });

  test('rejects non-PL2 frames', () {
    expect(codec.decodeFrame('INVALID|data'), isNull);
    expect(codec.decodeFrame(''), isNull);
  });
}
