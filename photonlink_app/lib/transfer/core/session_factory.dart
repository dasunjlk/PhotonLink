import 'dart:math';
import 'dart:typed_data';

import '../../core/constants.dart';
import '../../protocols/interfaces/chunk_manager.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../protocols/interfaces/transfer_session.dart';
import '../qr/qr_frame_codec.dart';
import '../qr/qr_transfer_limits.dart';
import 'chunking_engine.dart';
import 'integrity_verifier.dart';
import 'transfer_limits.dart';

/// Creates transfer sessions with metadata and chunked packets.
class SessionFactory {
  SessionFactory({
    ChunkManager? chunkManager,
    IntegrityVerifier? integrityVerifier,
  })  : _chunkManager = chunkManager ?? const ChunkingEngine(),
        _integrityVerifier = integrityVerifier ?? const IntegrityVerifier();

  final ChunkManager _chunkManager;
  final IntegrityVerifier _integrityVerifier;
  final _random = Random();

  String generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nonce = _random.nextInt(0xFFFFFF);
    return 'pl-${timestamp.toRadixString(36)}-${nonce.toRadixString(36)}';
  }

  /// Prepares sender session from raw file bytes (no compress/encrypt).
  SenderSessionBundle prepareSenderSessionFromFile({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    int? chunkSize,
  }) {
    final sha256 = _integrityVerifier.compute(fileBytes);
    return prepareSenderSession(
      wireBytes: fileBytes,
      fileName: fileName,
      mimeType: mimeType,
      wireSha256: sha256,
      originalSize: fileBytes.length,
      originalSha256: sha256,
      chunkSize: chunkSize,
    );
  }

  /// Prepares sender session from wire bytes (post compress/encrypt).
  SenderSessionBundle prepareSenderSession({
    required Uint8List wireBytes,
    required String fileName,
    required String mimeType,
    required String wireSha256,
    required int originalSize,
    required String originalSha256,
    CompressionType compression = CompressionType.none,
    EncryptionMode encryption = EncryptionMode.disabled,
    int? chunkSize,
    String? sessionIdOverride,
    bool skipQrFrameValidation = false,
  }) {
    TransferLimits.validateFileSize(wireBytes.length);

    final sessionId = sessionIdOverride ?? generateSessionId();

    final resolvedChunkSize = chunkSize ??
        QrTransferLimits.resolveChunkSize(
          sessionId: sessionId,
          fileBytes: wireBytes,
          chunkManager: _chunkManager,
        );

    final dataPackets = _chunkManager.split(
      data: wireBytes,
      sessionId: sessionId,
      chunkSize: resolvedChunkSize,
    );

    if (dataPackets.length > TransferLimits.maxTotalChunks) {
      throw TransferLimitException(
        'Too many chunks (${dataPackets.length}); file is too large for QR transfer',
      );
    }

    final metadata = MetadataPacket(
      sessionId: sessionId,
      fileName: fileName,
      fileSize: wireBytes.length,
      totalChunks: dataPackets.length,
      sha256: wireSha256,
      mimeType: mimeType,
      protocolVersion: AppConstants.protocolVersion,
      compression: compression,
      encryption: encryption,
      originalSize: originalSize,
      originalSha256: originalSha256,
    );

    TransferLimits.validateMetadata(
      fileName: metadata.fileName,
      fileSize: metadata.fileSize,
      totalChunks: metadata.totalChunks,
      sha256: metadata.sha256,
    );

    if (!skipQrFrameValidation) {
      const codec = QrFrameCodec();
      if (!QrTransferLimits.allDataFramesFit(
        sessionId,
        metadata,
        dataPackets,
        codec,
      )) {
        throw TransferLimitException(
          'Encoded QR frames exceed safe size limit',
        );
      }
    }

    final session = TransferSession(
      id: sessionId,
      fileName: fileName,
      fileSize: originalSize,
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
    );
  }
}

class SenderSessionBundle {
  const SenderSessionBundle({
    required this.session,
    required this.metadata,
    required this.dataPackets,
    this.setupPacket,
  });

  final TransferSession session;
  final MetadataPacket metadata;
  final List<DataPacket> dataPackets;
  final SessionSetupPacket? setupPacket;

  List<TransferPacket> get allPackets => [metadata, ...dataPackets];
}
