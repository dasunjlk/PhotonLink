import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/color_matrix/color_matrix_frame.dart';
import 'package:photonlink_app/transfer/color_matrix/color_matrix_frame_codec.dart';

void main() {
  test('corrupted cells fail decode', () {
    final codec = ColorMatrixFrameCodec(gridSize: 32);
    final frame = codec.encodeFrame(
      const MetadataPacket(
        sessionId: 'pl-corrupt',
        fileName: 'bad.txt',
        fileSize: 10,
        totalChunks: 1,
        sha256:
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        mimeType: 'text/plain',
      ),
    );

    final corruptedCells = frame.cells
        .map((c) => const ColorCell(r: 255, g: 255, b: 255))
        .toList();

    final corrupted = ColorMatrixFrame(
      protocolVersion: frame.protocolVersion,
      sessionId: frame.sessionId,
      frameId: frame.frameId,
      packetId: frame.packetId,
      isMetadata: frame.isMetadata,
      totalPackets: frame.totalPackets,
      payload: frame.payload,
      checksum: frame.checksum,
      gridSize: frame.gridSize,
      cells: corruptedCells,
    );

    expect(codec.decodeFrame(corrupted), isNull);
  });
}
