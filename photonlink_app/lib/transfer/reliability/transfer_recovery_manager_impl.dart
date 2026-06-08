import 'dart:convert';

import '../../protocols/interfaces/reliability/transfer_recovery_manager.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../core/session_store.dart';

/// Persists receive progress via [SessionStore] for resume.
class TransferRecoveryManagerImpl implements TransferRecoveryManager {
  TransferRecoveryManagerImpl(this._store);

  final SessionStore _store;

  @override
  Future<void> clearSnapshot(String sessionId) => _store.remove(sessionId);

  @override
  Future<RecoverySnapshot?> loadSnapshot(String sessionId) async {
    final snap = _store.load(sessionId);
    if (snap == null || snap.metadataJson == null) return null;
    final json = jsonDecode(snap.metadataJson!) as Map<String, dynamic>;
    final metadata = MetadataPacket.fromJson(snap.sessionId, json);
    return RecoverySnapshot(
      sessionId: snap.sessionId,
      metadata: metadata,
      receivedChunkIds: snap.receivedChunkIds.toSet(),
      direction: snap.direction ?? 'receive',
    );
  }

  @override
  Future<void> persistProgress({
    required String sessionId,
    required Set<int> receivedChunkIds,
    required MetadataPacket metadata,
    required String direction,
  }) async {
    await _store.save(
      SessionSnapshot(
        sessionId: sessionId,
        progress: receivedChunkIds.length / metadata.totalChunks,
        receivedChunkIds: receivedChunkIds.toList(),
        fileName: metadata.fileName,
        totalChunks: metadata.totalChunks,
        direction: direction,
        metadataJson: jsonEncode(metadata.toJson()),
      ),
    );
  }
}
