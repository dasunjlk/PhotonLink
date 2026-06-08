import 'dart:typed_data';

import '../../protocols/interfaces/transfer_packet.dart';
import 'chunking_engine.dart';

/// Collects, deduplicates, reorders, and rebuilds file bytes from packets.
class ReconstructionEngine {
  ReconstructionEngine({ChunkingEngine? chunkingEngine})
      : _chunkingEngine = chunkingEngine ?? const ChunkingEngine();

  final ChunkingEngine _chunkingEngine;
  MetadataPacket? _metadata;
  final Map<int, DataPacket> _chunks = {};

  MetadataPacket? get metadata => _metadata;

  int get receivedCount => _chunks.length;

  int get totalChunks => _metadata?.totalChunks ?? 0;

  bool get hasMetadata => _metadata != null;

  /// True only when every chunk index 0..totalChunks-1 is present.
  bool get isComplete {
    final meta = _metadata;
    if (meta == null || meta.totalChunks < 1) return false;
    if (_chunks.length != meta.totalChunks) return false;
    for (var i = 0; i < meta.totalChunks; i++) {
      if (!_chunks.containsKey(i)) return false;
    }
    return true;
  }

  double get progress {
    if (_metadata == null || _metadata!.totalChunks == 0) return 0;
    return _chunks.length / _metadata!.totalChunks;
  }

  /// Ingests a packet; returns true if it was new (not a duplicate).
  bool ingest(TransferPacket packet) {
    switch (packet) {
      case MetadataPacket metadata:
        if (_metadata != null &&
            _metadata!.sessionId != metadata.sessionId) {
          reset();
        } else if (_metadata == null) {
          _chunks.clear();
        }
        _metadata = metadata;
        return true;
      case DataPacket data:
        if (_metadata == null) return false;
        if (data.sessionId != _metadata!.sessionId) return false;
        if (data.totalChunks != _metadata!.totalChunks) return false;
        if (data.chunkId < 0 || data.chunkId >= _metadata!.totalChunks) {
          return false;
        }
        if (_chunks.containsKey(data.chunkId)) return false;
        _chunks[data.chunkId] = data;
        return true;
      case SessionSetupPacket():
      case AckPacket():
      case NakPacket():
      case HandshakePacket():
      case ControlPacket():
        return false;
    }
  }

  /// Returns reassembled bytes when all chunks are present, else null.
  Uint8List? rebuild() {
    if (!isComplete) return null;
    try {
      final packets = List<DataPacket>.generate(
        _metadata!.totalChunks,
        (i) => _chunks[i]!,
      );
      return _chunkingEngine.merge(packets);
    } catch (_) {
      return null;
    }
  }

  Set<int> get receivedChunkIds => _chunks.keys.toSet();

  void reset() {
    _metadata = null;
    _chunks.clear();
  }
}
