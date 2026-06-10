import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/core/chunking_engine.dart';
import 'package:photonlink_app/transfer/core/reconstruction_engine.dart';
import 'package:photonlink_app/transfer/core/session_factory.dart';

void main() {
  test('rebuilds file from out-of-order packets', () async {
    const engine = ChunkingEngine();
    final factory = SessionFactory(chunkManager: engine);
    final bytes = Uint8List.fromList(List.generate(800, (i) => i % 256));

    final bundle = factory.prepareSenderSessionFromFile(
      fileBytes: bytes,
      fileName: 'test.bin',
      mimeType: 'application/octet-stream',
    );

    final recon = ReconstructionEngine(chunkingEngine: engine);
    recon.ingest(bundle.metadata);

    final shuffled = List<DataPacket>.from(bundle.dataPackets)..shuffle();
    for (final p in shuffled) {
      recon.ingest(p);
    }

    expect(recon.isComplete, isTrue);
    expect(recon.rebuild(), bytes);
  });

  test('duplicate packets are ignored', () async {
    const engine = ChunkingEngine();
    final factory = SessionFactory(chunkManager: engine);
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

    final bundle = factory.prepareSenderSessionFromFile(
      fileBytes: bytes,
      fileName: 'tiny.bin',
      mimeType: 'application/octet-stream',
      chunkSize: 10,
    );

    final recon = ReconstructionEngine(chunkingEngine: engine);
    recon.ingest(bundle.metadata);

    for (final p in bundle.dataPackets) {
      expect(recon.ingest(p), isTrue);
      expect(recon.ingest(p), isFalse);
    }

    expect(recon.receivedCount, bundle.dataPackets.length);
    expect(recon.rebuild(), bytes);
  });

  test('rebuild returns null when incomplete', () {
    final recon = ReconstructionEngine();
    recon.ingest(
      const MetadataPacket(
        sessionId: 's',
        fileName: 'f',
        fileSize: 100,
        totalChunks: 5,
        sha256:
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        mimeType: 'application/octet-stream',
      ),
    );
    expect(recon.isComplete, isFalse);
    expect(recon.rebuild(), isNull);
  });
}
