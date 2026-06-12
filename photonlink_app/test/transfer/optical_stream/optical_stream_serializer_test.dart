import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/optical_stream/optical_stream_frame.dart';
import 'package:photonlink_app/transfer/optical_stream/optical_stream_serializer.dart';

void main() {
  test('PLOS serializer roundtrip', () {
    final frame = OpticalStreamFrame(
      protocolVersion: 1,
      sessionId: 'test-session',
      streamId: 1,
      frameId: 42,
      packetId: 7,
      packetType: OpticalStreamPacketType.data,
      totalPackets: 10,
      payload: Uint8List.fromList([1, 2, 3, 4, 5]),
      checksum: 0,
      syncMarker: OpticalStreamFrame.defaultSyncMarker,
      timestamp: 1700000000000,
      gridSize: 24,
      bitsPerCell: 1,
    );

    final bytes = OpticalStreamSerializer.serialize(frame);
    final decoded = OpticalStreamSerializer.deserialize(bytes);
    expect(decoded, isNotNull);
    expect(decoded!.sessionId, 'test-session');
    expect(decoded.frameId, 42);
    expect(decoded.packetId, 7);
    expect(decoded.payload, frame.payload);
    expect(decoded.syncMarker, OpticalStreamFrame.defaultSyncMarker);
  });

  test('PLOS serializer rejects bad checksum', () {
    final frame = OpticalStreamFrame(
      protocolVersion: 1,
      sessionId: 'x',
      streamId: 1,
      frameId: 0,
      packetId: 0,
      packetType: OpticalStreamPacketType.data,
      totalPackets: 1,
      payload: Uint8List(0),
      checksum: 0,
      syncMarker: 0,
      timestamp: 0,
      gridSize: 16,
      bitsPerCell: 1,
    );
    final bytes = OpticalStreamSerializer.serialize(frame);
    bytes[bytes.length - 1] ^= 0xFF;
    expect(OpticalStreamSerializer.deserialize(bytes), isNull);
  });
}
