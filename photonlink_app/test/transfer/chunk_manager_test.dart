import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/core/chunking_engine.dart';

void main() {
  const engine = ChunkingEngine();
  const sessionId = 'test-session';

  test('splits file into correct number of chunks', () {
    final data = Uint8List.fromList(List.generate(1200, (i) => i % 256));
    final packets = engine.split(
      data: data,
      sessionId: sessionId,
      chunkSize: 512,
    );

    expect(packets.length, 3);
    expect(packets.first.chunkId, 0);
    expect(packets.last.chunkId, 2);
    expect(packets.every((p) => p.totalChunks == 3), isTrue);
    expect(packets.every((p) => p.sessionId == sessionId), isTrue);
  });

  test('last chunk has remainder size', () {
    final data = Uint8List.fromList(List.generate(600, (i) => i % 256));
    final packets = engine.split(data: data, sessionId: sessionId, chunkSize: 512);

    expect(packets.length, 2);
    expect(packets[0].payload.length, 512);
    expect(packets[1].payload.length, 88);
  });

  test('empty file produces single empty chunk', () {
    final packets = engine.split(
      data: Uint8List(0),
      sessionId: sessionId,
    );
    expect(packets.length, 1);
    expect(packets.first.payload.length, 0);
  });

  test('merge restores original bytes', () {
    final original = Uint8List.fromList(List.generate(999, (i) => i % 256));
    final packets = engine.split(data: original, sessionId: sessionId);
    final merged = engine.merge(packets);
    expect(merged, original);
  });
}
