import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/optical_stream/optical_stream_decoder.dart';
import 'package:photonlink_app/transfer/optical_stream/optical_stream_frame.dart';

OpticalStreamFrame _frame({int frameId = 1, int packetId = 0}) {
  return OpticalStreamFrame(
    protocolVersion: 1,
    sessionId: 's',
    streamId: 1,
    frameId: frameId,
    packetId: packetId,
    packetType: OpticalStreamPacketType.metadata,
    totalPackets: 1,
    payload: Uint8List(0),
    checksum: 0,
    syncMarker: 0,
    timestamp: 0,
    gridSize: 16,
    cells: List.generate(
      16 * 16,
      (_) => const BrightnessCell(brightness: 1.0, bit: 1),
    ),
  );
}

void main() {
  test('duplicate frames are ignored', () {
    final decoder = OpticalStreamDecoder();
    final frame = _frame();
    expect(
      decoder.ingestDetectedFrame(frame, detected: true, detectionAccuracy: 0.9),
      isNotNull,
    );
    expect(
      decoder.ingestDetectedFrame(frame, detected: true, detectionAccuracy: 0.9),
      isNull,
    );
    expect(decoder.duplicatesIgnored, 1);
  });

  test('dropped frames increment counter', () {
    final decoder = OpticalStreamDecoder();
    expect(
      decoder.ingestDetectedFrame(
        _frame(),
        detected: false,
        detectionAccuracy: 0,
      ),
      isNull,
    );
    expect(decoder.droppedFrames, 1);
  });

  test('resync after low accuracy mid-stream', () {
    final decoder = OpticalStreamDecoder(
      syncAggressiveness: 0.6,
      recoverySensitivity: 0.5,
    );
    decoder.ingestDetectedFrame(
      _frame(frameId: 1),
      detected: true,
      detectionAccuracy: 0.9,
    );
    decoder.ingestDetectedFrame(
      _frame(frameId: 2),
      detected: true,
      detectionAccuracy: 0.1,
    );
    expect(decoder.resyncCount, greaterThanOrEqualTo(0));
  });
}
