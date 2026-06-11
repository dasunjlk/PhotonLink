import 'dart:typed_data';

import 'compression_type.dart';
import 'encryption_mode.dart';

/// Transport-agnostic packet types for optical file transfer.
sealed class TransferPacket {
  const TransferPacket({required this.sessionId});

  final String sessionId;
}

/// Session setup with key exchange payload (before metadata).
final class SessionSetupPacket extends TransferPacket {
  const SessionSetupPacket({
    required super.sessionId,
    required this.protocolVersion,
    required this.keyExchangePayload,
    required this.compression,
    required this.encryption,
    required this.timestamp,
  });

  final int protocolVersion;
  final String keyExchangePayload;
  final CompressionType compression;
  final EncryptionMode encryption;
  final DateTime timestamp;
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
    this.protocolVersion = 1,
    this.compression = CompressionType.none,
    this.encryption = EncryptionMode.disabled,
    this.originalSize,
    this.originalSha256,
  });

  final String fileName;
  /// Wire payload size (after compress/encrypt).
  final int fileSize;
  final int totalChunks;
  /// SHA-256 of wire payload.
  final String sha256;
  final String mimeType;
  final int protocolVersion;
  final CompressionType compression;
  final EncryptionMode encryption;
  /// Original plaintext size before transforms.
  final int? originalSize;
  /// SHA-256 of original plaintext (optional for v1 compat).
  final String? originalSha256;
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

/// Reed-Solomon parity packet for FEC recovery.
final class ParityPacket extends TransferPacket {
  const ParityPacket({
    required super.sessionId,
    required this.parityId,
    required this.blockIndex,
    required this.parityIndexInBlock,
    required this.dataCount,
    required this.parityCount,
    required this.dataSymbolLength,
    required this.totalParity,
    required this.totalChunks,
    required this.payload,
  });

  final int parityId;
  final int blockIndex;
  final int parityIndexInBlock;
  final int dataCount;
  final int parityCount;
  final int dataSymbolLength;
  final int totalParity;
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
    ParityPacket parity => parity.parityId,
    _ => -1,
  };
}
