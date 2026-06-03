import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/core/reconstruction_engine.dart';
import 'package:photonlink_app/transfer/core/transfer_limits.dart';

void main() {
  const validHash =
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

  test('rejects data packets before metadata', () {
    final recon = ReconstructionEngine();
    final accepted = recon.ingest(
      DataPacket(
        sessionId: 's1',
        chunkId: 0,
        totalChunks: 1,
        payload: Uint8List.fromList([1]),
      ),
    );
    expect(accepted, isFalse);
    expect(recon.hasMetadata, isFalse);
  });

  test('non-contiguous chunk ids do not mark complete', () {
    final recon = ReconstructionEngine();
    recon.ingest(
      MetadataPacket(
        sessionId: 's1',
        fileName: 'f.bin',
        fileSize: 3,
        totalChunks: 3,
        sha256: validHash,
        mimeType: 'application/octet-stream',
      ),
    );
    recon.ingest(
      DataPacket(
        sessionId: 's1',
        chunkId: 5,
        totalChunks: 3,
        payload: Uint8List.fromList([1]),
      ),
    );
    recon.ingest(
      DataPacket(
        sessionId: 's1',
        chunkId: 6,
        totalChunks: 3,
        payload: Uint8List.fromList([2]),
      ),
    );
    recon.ingest(
      DataPacket(
        sessionId: 's1',
        chunkId: 7,
        totalChunks: 3,
        payload: Uint8List.fromList([3]),
      ),
    );
    expect(recon.isComplete, isFalse);
    expect(recon.rebuild(), isNull);
  });

  test('rejects chunk id out of range', () {
    final recon = ReconstructionEngine();
    recon.ingest(
      MetadataPacket(
        sessionId: 's1',
        fileName: 'f.bin',
        fileSize: 1,
        totalChunks: 2,
        sha256: validHash,
        mimeType: 'application/octet-stream',
      ),
    );
    expect(
      recon.ingest(
        DataPacket(
          sessionId: 's1',
          chunkId: 2,
          totalChunks: 2,
          payload: Uint8List(1),
        ),
      ),
      isFalse,
    );
  });

  test('validateFileSize rejects oversized files', () {
    expect(
      () => TransferLimits.validateFileSize(TransferLimits.maxFileBytes + 1),
      throwsA(isA<TransferLimitException>()),
    );
  });
}
