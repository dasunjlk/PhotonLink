import 'dart:convert';
import 'dart:typed_data';

import 'compression_type.dart';
import 'encryption_mode.dart';

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
    this.compression = CompressionType.none,
    this.encryption = EncryptionMode.none,
    this.transformedSize,
    this.kdfSalt,
    this.encryptionNonce,
  });

  final String fileName;
  final int fileSize;
  final int totalChunks;
  final String sha256;
  final String mimeType;
  final CompressionType compression;
  final EncryptionMode encryption;
  final int? transformedSize;
  final Uint8List? kdfSalt;
  final Uint8List? encryptionNonce;

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'fileSize': fileSize,
        'totalChunks': totalChunks,
        'sha256': sha256,
        'mimeType': mimeType,
        'compression': compression.id,
        'encryption': encryption.id,
        if (transformedSize != null) 'transformedSize': transformedSize,
        if (kdfSalt != null) 'kdfSalt': base64Encode(kdfSalt!),
        if (encryptionNonce != null) 'encryptionNonce': base64Encode(encryptionNonce!),
      };

  factory MetadataPacket.fromJson(String sessionId, Map<String, dynamic> json) {
    return MetadataPacket(
      sessionId: sessionId,
      fileName: json['fileName'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? -1,
      totalChunks: json['totalChunks'] as int? ?? 0,
      sha256: json['sha256'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      compression: CompressionType.fromId(json['compression'] as String?),
      encryption: EncryptionMode.fromId(json['encryption'] as String?),
      transformedSize: json['transformedSize'] as int?,
      kdfSalt: json['kdfSalt'] != null
          ? Uint8List.fromList(base64Decode(json['kdfSalt'] as String))
          : null,
      encryptionNonce: json['encryptionNonce'] != null
          ? Uint8List.fromList(base64Decode(json['encryptionNonce'] as String))
          : null,
    );
  }
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
