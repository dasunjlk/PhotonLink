import 'dart:typed_data';

/// Transport-agnostic packet types for optical file transfer.
sealed class TransferPacket {
  const TransferPacket({required this.sessionId});

  final String sessionId;
}

/// Session metadata broadcast before data chunks.
final class MetadataPacket extends TransferPacket {
  const MetadataPacket({
    required super.sessionId,
    required this.fileName,
    required this.fileSize,
    required this.totalChunks,
    required this.sha256,
    required this.mimeType,
  });

  final String fileName;
  final int fileSize;
  final int totalChunks;
  final String sha256;
  final String mimeType;
}

/// A single file chunk payload.
final class DataPacket extends TransferPacket {
  const DataPacket({
    required super.sessionId,
    required this.chunkId,
    required this.totalChunks,
    required this.payload,
  });

  final int chunkId;
  final int totalChunks;
  final Uint8List payload;
}

/// Receiver confirms successfully received packet IDs.
final class AckPacket extends TransferPacket {
  const AckPacket({
    required super.sessionId,
    required this.packetIds,
    required this.timestamp,
  });

  final List<int> packetIds;
  final DateTime timestamp;
}

/// Receiver requests retransmission of missing packet IDs.
final class NakPacket extends TransferPacket {
  const NakPacket({
    required super.sessionId,
    required this.missingPacketIds,
    required this.timestamp,
  });

  final List<int> missingPacketIds;
  final DateTime timestamp;
}

/// Receiver readiness and resume state (already-received IDs).
final class HandshakePacket extends TransferPacket {
  const HandshakePacket({
    required super.sessionId,
    required this.receivedChunkIds,
    required this.timestamp,
  });

  final List<int> receivedChunkIds;
  final DateTime timestamp;
}

/// Control signals for round handoff and lifecycle.
enum ControlType {
  ready,
  endOfRound,
  complete,
  pause,
  cancel,
  resumeRequest,
}

/// Session control / round boundary packet.
final class ControlPacket extends TransferPacket {
  const ControlPacket({
    required super.sessionId,
    required this.type,
    required this.timestamp,
  });

  final ControlType type;
  final DateTime timestamp;
}

/// Returns chunk ID for data packets, or -1 for non-data packets.
int packetIdOf(TransferPacket packet) {
  return switch (packet) {
    DataPacket data => data.chunkId,
    _ => -1,
  };
}
