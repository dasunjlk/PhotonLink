import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/color_matrix/color_frame_detector.dart';
import 'package:photonlink_app/transfer/color_matrix/color_frame_generator.dart';
import 'package:photonlink_app/transfer/color_matrix/color_matrix_frame_codec.dart';

void main() {
  test('generated raster roundtrips through detector', () {
    final codec = ColorMatrixFrameCodec(gridSize: 32);
    const generator = ColorFrameGenerator(imageSize: 320);
    const detector = ColorFrameDetector(defaultGridSize: 32);

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

    final detection = detector.detect(raster, gridSize: 32);
    expect(detection.detected, isTrue);
    expect(detection.cells.length, 32 * 32);
    expect(detection.accuracy, greaterThan(0.5));

    final decodedFrame = frame.copyWith(cells: detection.cells);
    final packet = codec.decodeFrame(decodedFrame);
    expect(packet, isA<MetadataPacket>());
    expect((packet as MetadataPacket).fileName, 'test.txt');
  });
}
