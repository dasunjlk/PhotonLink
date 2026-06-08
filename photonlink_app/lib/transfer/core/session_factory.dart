import 'dart:math';
import 'dart:typed_data';

import '../../protocols/interfaces/chunk_manager.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../protocols/interfaces/transfer_session.dart';
import '../../protocols/interfaces/transport_limits_resolver.dart';
import 'chunking_engine.dart';
import 'integrity_verifier.dart';
import 'payload_pipeline.dart';
import 'transfer_limits.dart';

/// Creates transfer sessions with metadata and chunked packets.
class SessionFactory {
  SessionFactory({
    ChunkManager? chunkManager,
    IntegrityVerifier? integrityVerifier,
    PayloadPipeline? payloadPipeline,
  })  : _chunkManager = chunkManager ?? const ChunkingEngine(),
        _integrityVerifier = integrityVerifier ?? const IntegrityVerifier(),
        _payloadPipeline = payloadPipeline ?? PayloadPipeline();

  final ChunkManager _chunkManager;
  final IntegrityVerifier _integrityVerifier;
  final PayloadPipeline _payloadPipeline;
  final _random = Random();

  String generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nonce = _random.nextInt(0xFFFFFF);
    return 'pl-${timestamp.toRadixString(36)}-${nonce.toRadixString(36)}';
  }

  /// Prepares a full sender session: metadata + data packets.
  Future<SenderSessionBundle> prepareSenderSession({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    required TransportLimitsResolver limits,
    required TransferEncoder encoder,
    int? chunkSize,
    bool compressionEnabled = false,
    bool encryptionEnabled = false,
    String passphrase = '',
  }) async {
    _validateFileSize(fileBytes.length, limits.maxFileBytes);

    final sessionId = generateSessionId();
    final originalSha256 = _integrityVerifier.compute(fileBytes);

    final transformed = await _payloadPipeline.forward(
      plaintext: fileBytes,
      compressionEnabled: compressionEnabled,
      encryptionEnabled: encryptionEnabled,
      passphrase: passphrase,
    );

    final resolvedChunkSize = chunkSize ??
        limits.resolveChunkSize(
          sessionId: sessionId,
          fileBytes: transformed.bytes,
          chunkManager: _chunkManager,
          encoder: encoder,
        );

    final dataPackets = _chunkManager.split(
      data: transformed.bytes,
      sessionId: sessionId,
      chunkSize: resolvedChunkSize,
    );

    if (dataPackets.length > TransferLimits.maxTotalChunks) {
      throw TransferLimitException(
        'Too many chunks (${dataPackets.length}); file is too large for ${limits.transportLabel}',
      );
    }

    final metadata = MetadataPacket(
      sessionId: sessionId,
      fileName: fileName,
      fileSize: fileBytes.length,
      totalChunks: dataPackets.length,
      sha256: originalSha256,
      mimeType: mimeType,
      compression: transformed.compression,
      encryption: transformed.encryption,
      transformedSize: transformed.bytes.length,
      kdfSalt: transformed.kdfSalt,
      encryptionNonce: transformed.encryptionNonce,
    );

    TransferLimits.validateMetadata(
      fileName: metadata.fileName,
      fileSize: metadata.fileSize,
      totalChunks: metadata.totalChunks,
      sha256: metadata.sha256,
    );

    if (!limits.allFramesFit(
      sessionId: sessionId,
      metadata: metadata,
      dataPackets: dataPackets,
      encoder: encoder,
    )) {
      throw TransferLimitException(
        'Encoded frames exceed safe size limit for ${limits.transportLabel}',
      );
    }

    final session = TransferSession(
      id: sessionId,
      fileName: fileName,
      fileSize: fileBytes.length,
      totalChunks: dataPackets.length,
      sha256: originalSha256,
      mimeType: mimeType,
      state: TransferSessionState.preparing,
      startedAt: DateTime.now(),
    );

    return SenderSessionBundle(
      session: session,
      metadata: metadata,
      dataPackets: dataPackets,
      compression: transformed.compression,
      encryption: transformed.encryption,
      kdfSalt: transformed.kdfSalt,
      encryptionNonce: transformed.encryptionNonce,
    );
  }

  void _validateFileSize(int sizeBytes, int maxBytes) {
    if (sizeBytes < 0) {
      throw TransferLimitException('Invalid file size');
    }
    if (sizeBytes > maxBytes) {
      throw TransferLimitException(
        'File exceeds ${maxBytes ~/ 1024} KB limit',
      );
    }
  }
}

/// Bundle returned when preparing a sender session.
class SenderSessionBundle {
  const SenderSessionBundle({
    required this.session,
    required this.metadata,
    required this.dataPackets,
    this.compression = CompressionType.none,
    this.encryption = EncryptionMode.none,
    this.kdfSalt,
    this.encryptionNonce,
  });

  final TransferSession session;
  final MetadataPacket metadata;
  final List<DataPacket> dataPackets;
  final CompressionType compression;
  final EncryptionMode encryption;
  final Uint8List? kdfSalt;
  final Uint8List? encryptionNonce;

  List<TransferPacket> get allPackets => [metadata, ...dataPackets];
}
