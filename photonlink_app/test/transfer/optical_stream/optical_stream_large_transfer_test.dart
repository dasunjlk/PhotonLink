import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/core/chunking_engine.dart';
import 'package:photonlink_app/transfer/optical_stream/optical_stream_codec.dart';
import 'package:photonlink_app/transfer/optical_stream/optical_stream_transfer_limits.dart';

void main() {
  test('large transfer chunk sizing resolves for optical stream grid', () {
    final codec = OpticalStreamFrameCodec(gridSize: 48, bitsPerCell: 3);
    const sessionId = 'large-os-session';
    final fileBytes = Uint8List.fromList(
      List.generate(8 * 1024, (i) => i % 256),
    );

    final chunkSize = OpticalStreamTransferLimits.resolveChunkSize(
      sessionId: sessionId,
      fileBytes: fileBytes,
      chunkManager: const ChunkingEngine(),
      encoder: codec,
      fileName: 'large.bin',
    );

    expect(chunkSize, greaterThan(0));
    expect(
      OpticalStreamTransferLimits.allFramesFit(
        sessionId: sessionId,
        metadata: MetadataPacket(
          sessionId: sessionId,
          fileName: 'large.bin',
          fileSize: fileBytes.length,
          totalChunks: (fileBytes.length / chunkSize).ceil(),
          sha256:
              'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
          mimeType: 'application/octet-stream',
        ),
        dataPackets: [
          DataPacket(
            sessionId: sessionId,
            chunkId: 0,
            totalChunks: 1,
            payload: fileBytes.sublist(0, chunkSize.clamp(0, fileBytes.length)),
          ),
        ],
        encoder: codec,
      ),
      isTrue,
    );
  });
}
