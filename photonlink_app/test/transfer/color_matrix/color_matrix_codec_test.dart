import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/color_matrix/color_matrix_frame_codec.dart';

void main() {
  test('metadata packet roundtrip through codec', () {
    final codec = ColorMatrixFrameCodec(gridSize: 32);
    const metadata = MetadataPacket(
      sessionId: 'pl-test-session',
      fileName: 'hello.txt',
      fileSize: 100,
      totalChunks: 3,
      sha256:
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      mimeType: 'text/plain',
    );

    final frame = codec.encodeFrame(metadata);
    expect(frame.cells.length, 32 * 32);

    final decoded = codec.decodeFrame(frame);
    expect(decoded, isA<MetadataPacket>());
    expect((decoded as MetadataPacket).fileName, 'hello.txt');
    expect(decoded.totalChunks, 3);
  });

  test('data packet roundtrip through codec', () {
    final codec = ColorMatrixFrameCodec(gridSize: 32);
    final payload = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

    final frame = codec.encodeFrame(
      DataPacket(
        sessionId: 'pl-test',
        chunkId: 1,
        totalChunks: 5,
        payload: payload,
      ),
    );

    final decoded = codec.decodeFrame(frame);
    expect(decoded, isA<DataPacket>());
    final data = decoded as DataPacket;
    expect(data.chunkId, 1);
    expect(data.payload, payload);
  });
}
