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
