import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/color_matrix/color_frame_detector.dart';
import 'package:photonlink_app/transfer/color_matrix/color_frame_generator.dart';
import 'package:photonlink_app/transfer/color_matrix/color_matrix_frame_codec.dart';

void main() {
  test('generates non-empty raster from frame', () {
    final codec = ColorMatrixFrameCodec(gridSize: 32);
    const generator = ColorFrameGenerator(imageSize: 320);

    final frame = codec.encodeFrame(
      const MetadataPacket(
        sessionId: 'pl-roundtrip',
        fileName: 'test.txt',
        fileSize: 50,
        totalChunks: 2,
        sha256:
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        mimeType: 'text/plain',
      ),
    );

    final raster = generator.generateRaster(frame);
    expect(raster.isNotEmpty, isTrue);
  });

  test('cells roundtrip through codec without raster loss', () {
    final codec = ColorMatrixFrameCodec(gridSize: 32);

    final frame = codec.encodeFrame(
      const MetadataPacket(
        sessionId: 'pl-cells',
        fileName: 'cells.txt',
        fileSize: 50,
        totalChunks: 2,
        sha256:
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        mimeType: 'text/plain',
      ),
    );

    final decodedFrame = frame.copyWith(cells: frame.cells);
    final packet = codec.decodeFrame(decodedFrame);
    expect(packet, isA<MetadataPacket>());
    expect((packet as MetadataPacket).fileName, 'cells.txt');
  });

  test('detector extracts cells from generated raster', () {
    final codec = ColorMatrixFrameCodec(gridSize: 32);
    const generator = ColorFrameGenerator(imageSize: 320);
    const detector = ColorFrameDetector(defaultGridSize: 32);

    final frame = codec.encodeFrame(
      DataPacket(
        sessionId: 'pl-detect',
        chunkId: 0,
        totalChunks: 1,
        payload: Uint8List.fromList([1, 2, 3, 4]),
      ),
    );

    final raster = generator.generateRaster(frame);
    final detection = detector.detect(raster, gridSize: 32);
    expect(detection.detected, isTrue);
    expect(detection.cells.length, 32 * 32);
  });
}
