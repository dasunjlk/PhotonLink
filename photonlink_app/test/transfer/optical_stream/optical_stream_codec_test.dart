import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/optical_stream/optical_stream_codec.dart';

void main() {
  test('metadata packet roundtrip through codec', () {
    final codec = OpticalStreamFrameCodec(gridSize: 48, bitsPerCell: 3);
    const metadata = MetadataPacket(
      sessionId: 'os-test-session',
      fileName: 'hello.txt',
      fileSize: 100,
      totalChunks: 3,
      sha256:
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      mimeType: 'text/plain',
    );

    final frame = codec.encodeFrame(metadata);
    expect(frame.cells.length, 48 * 48);

    final decoded = codec.decodeFrame(frame);
    expect(decoded, isA<MetadataPacket>());
    expect((decoded as MetadataPacket).fileName, 'hello.txt');
    expect(decoded.totalChunks, 3);
  });

  test('data packet roundtrip through codec', () {
    final codec = OpticalStreamFrameCodec(gridSize: 48, bitsPerCell: 3);
    final data = DataPacket(
      sessionId: 'os-test',
      chunkId: 1,
      totalChunks: 5,
      payload: Uint8List.fromList([10, 20, 30, 40]),
    );

    final frame = codec.encodeFrame(data);
    final decoded = codec.decodeFrame(frame);
    expect(decoded, isA<DataPacket>());
    expect((decoded as DataPacket).chunkId, 1);
    expect(decoded.payload, data.payload);
  });
}
