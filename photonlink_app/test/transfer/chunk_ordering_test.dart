import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/core/chunking_engine.dart';

void main() {
  const engine = ChunkingEngine();

  test('merge sorts packets by chunkId regardless of input order', () {
    final original = Uint8List.fromList(List.generate(300, (i) => i));
    final packets = engine.split(data: original, sessionId: 's1', chunkSize: 100);

    final shuffled = [packets[2], packets[0], packets[1]];
    final merged = engine.merge(shuffled);
    expect(merged, original);
  });

  test('DataPacket ordering by chunkId', () {
    final list = [
      DataPacket(sessionId: 's', chunkId: 2, totalChunks: 3, payload: Uint8List(0)),
      DataPacket(sessionId: 's', chunkId: 0, totalChunks: 3, payload: Uint8List(0)),
      DataPacket(sessionId: 's', chunkId: 1, totalChunks: 3, payload: Uint8List(0)),
    ];
    list.sort((a, b) => a.chunkId.compareTo(b.chunkId));
    expect(list.map((p) => p.chunkId).toList(), [0, 1, 2]);
  });
}
