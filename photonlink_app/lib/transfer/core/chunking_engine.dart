import 'dart:typed_data';

import '../../protocols/interfaces/chunk_manager.dart';
import '../../protocols/interfaces/transfer_packet.dart';

/// Fixed-size chunk splitter and merger (transport-agnostic).
class ChunkingEngine implements ChunkManager {
  const ChunkingEngine();

  @override
  List<DataPacket> split({
    required Uint8List data,
    required String sessionId,
    int chunkSize = ChunkManager.defaultChunkSize,
  }) {
    if (data.isEmpty) {
      return [
        DataPacket(
          sessionId: sessionId,
          chunkId: 0,
          totalChunks: 1,
          payload: Uint8List(0),
        ),
      ];
    }

    final totalChunks = (data.length / chunkSize).ceil();
    final packets = <DataPacket>[];

    for (var i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = (start + chunkSize < data.length) ? start + chunkSize : data.length;
      packets.add(
        DataPacket(
          sessionId: sessionId,
          chunkId: i,
          totalChunks: totalChunks,
          payload: Uint8List.sublistView(data, start, end),
        ),
      );
    }

    return packets;
  }

  @override
  Uint8List merge(List<DataPacket> packets) {
    if (packets.isEmpty) return Uint8List(0);

    final ordered = List<DataPacket>.from(packets)
      ..sort((a, b) => a.chunkId.compareTo(b.chunkId));

    final totalLength = ordered.fold<int>(
      0,
      (sum, p) => sum + p.payload.length,
    );

    final result = Uint8List(totalLength);
    var offset = 0;
    for (final packet in ordered) {
      result.setRange(offset, offset + packet.payload.length, packet.payload);
      offset += packet.payload.length;
    }

    return result;
  }
}
