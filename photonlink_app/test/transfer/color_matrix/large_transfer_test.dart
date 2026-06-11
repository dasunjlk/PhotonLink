import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/color_matrix/color_matrix_frame_codec.dart';
import 'package:photonlink_app/transfer/color_matrix/color_matrix_transfer_limits.dart';
import 'package:photonlink_app/transfer/core/chunking_engine.dart';

void main() {
  test('large file chunks fit in color matrix frames', () {
    const engine = ChunkingEngine();
    final codec = ColorMatrixFrameCodec(gridSize: 32);
    final bytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));

    final chunkSize = ColorMatrixTransferLimits.resolveChunkSize(
      sessionId: 'pl-large',
      fileBytes: bytes,
      chunkManager: engine,
      encoder: codec,
      fileName: 'large.bin',
    );

    expect(chunkSize, greaterThan(0));
    final packets = engine.split(
      data: bytes,
      sessionId: 'pl-large',
      chunkSize: chunkSize,
    );
    expect(packets.length, greaterThan(1));
  });
}
