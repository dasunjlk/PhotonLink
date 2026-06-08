import '../transfer_packet.dart';

/// Resume and recovery from persisted session state.
abstract interface class TransferRecoveryManager {
  Future<void> persistProgress({
    required String sessionId,
    required Set<int> receivedChunkIds,
    required MetadataPacket metadata,
    required String direction,
  });

  Future<RecoverySnapshot?> loadSnapshot(String sessionId);
  Future<void> clearSnapshot(String sessionId);
}

/// Snapshot of recoverable receive progress.
class RecoverySnapshot {
  const RecoverySnapshot({
    required this.sessionId,
    required this.metadata,
    required this.receivedChunkIds,
    required this.direction,
  });

  final String sessionId;
  final MetadataPacket metadata;
  final Set<int> receivedChunkIds;
  final String direction;
}
