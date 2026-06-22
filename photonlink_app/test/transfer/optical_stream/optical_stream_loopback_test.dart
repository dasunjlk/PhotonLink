import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/optical_stream/optical_brightness_decoder.dart';
import 'package:photonlink_app/transfer/optical_stream/optical_brightness_encoder.dart';
import 'package:photonlink_app/transfer/optical_stream/optical_stream_codec.dart';
import 'package:photonlink_app/transfer/optical_stream/optical_stream_frame.dart';
import 'package:photonlink_app/transfer/optical_stream/optical_stream_serializer.dart';

void main() {
  test('continuous encoder-decoder loopback', () {
    final codec = OpticalStreamFrameCodec(gridSize: 48, bitsPerCell: 3);
    final packets = <TransferPacket>[
      const MetadataPacket(
        sessionId: 'loop-session',
        fileName: 'test.bin',
        fileSize: 64,
        totalChunks: 2,
        sha256:
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        mimeType: 'application/octet-stream',
      ),
      DataPacket(
        sessionId: 'loop-session',
        chunkId: 0,
        totalChunks: 2,
        payload: Uint8List.fromList(List.generate(32, (i) => i)),
      ),
      DataPacket(
        sessionId: 'loop-session',
        chunkId: 1,
        totalChunks: 2,
        payload: Uint8List.fromList(List.generate(32, (i) => i + 32)),
      ),
    ];

    var decodedCount = 0;
    for (final packet in packets) {
      final frame = codec.encodeFrame(packet);
      final decoded = codec.decodeFrame(frame);
      expect(decoded, isNotNull);
      decodedCount++;
    }
    expect(decodedCount, packets.length);
  });

  test('brightness lane roundtrip preserves bytes', () {
    const gridSize = 48;
    const bitsPerCell = 3;
    final encoder = OpticalBrightnessEncoder(bitsPerCell: bitsPerCell);
    final decoder = OpticalBrightnessDecoder(bitsPerCell: bitsPerCell);
    final payload = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
    final serialized = OpticalStreamSerializer.serialize(
      OpticalStreamFrame(
        protocolVersion: 1,
        sessionId: 'x',
        streamId: 1,
        frameId: 0,
        packetId: 0,
        packetType: OpticalStreamPacketType.data,
        totalPackets: 1,
        payload: payload,
        checksum: 0,
        syncMarker: 0,
        timestamp: 0,
        gridSize: gridSize,
        bitsPerCell: bitsPerCell,
      ),
    );
    final cells = encoder.encodeBytes(serialized, gridSize: gridSize);
    final result = decoder.decodeCells(
      cells,
      expectedByteLength: serialized.length,
    );
    expect(result.valid, isTrue);
    expect(result.frameBytes, serialized);
  });
}
