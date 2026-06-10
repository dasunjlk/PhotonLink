import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/core/chunking_engine.dart';
import 'package:photonlink_app/transfer/core/integrity_verifier.dart';
import 'package:photonlink_app/transfer/core/reconstruction_engine.dart';
import 'package:photonlink_app/transfer/core/session_factory.dart';
import 'package:photonlink_app/transfer/reliability/transfer_recovery_manager_impl.dart';

void main() {
  test('resume missing set excludes received chunks', () {
    final recovery = TransferRecoveryManagerImpl();
    const engine = ChunkingEngine();
    final factory = SessionFactory(chunkManager: engine);
    final bytes = Uint8List.fromList(List.generate(300, (i) => i % 256));

    final bundle = factory.prepareSenderSessionFromFile(
      fileBytes: bytes,
      fileName: 'r.bin',
      mimeType: 'application/octet-stream',
      chunkSize: 100,
    );

    final received = {0, 2};
    final missing = recovery.computeMissingIds(
      totalPackets: bundle.metadata.totalChunks,
      receivedIds: received,
    );

    final recon = ReconstructionEngine(chunkingEngine: engine);
    recon.ingest(bundle.metadata);
    for (final p in bundle.dataPackets) {
      if (received.contains(p.chunkId)) recon.ingest(p);
    }
    expect(recon.isComplete, isFalse);

    for (final id in missing) {
      recon.ingest(bundle.dataPackets.firstWhere((p) => p.chunkId == id));
    }
    expect(recon.isComplete, isTrue);
    final rebuilt = recon.rebuild()!;
    const IntegrityVerifier().verify(rebuilt, bundle.metadata.sha256);
    expect(
      const IntegrityVerifier().verify(rebuilt, bundle.metadata.sha256),
      isTrue,
    );
  });
}
