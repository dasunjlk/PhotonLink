import 'dart:math';
import 'dart:typed_data';

import '../../protocols/interfaces/chunk_manager.dart';
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

  /// Generates a unique session ID.
  String generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nonce = _random.nextInt(0xFFFFFF);
    return 'pl-${timestamp.toRadixString(36)}-${nonce.toRadixString(36)}';
  }

  /// Prepares a full sender session: metadata + data packets.
  SenderSessionBundle prepareSenderSession({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    int? chunkSize,
  }) {
    TransferLimits.validateFileSize(fileBytes.length);

    final sessionId = generateSessionId();
    final sha256 = _integrityVerifier.compute(fileBytes);

    final resolvedChunkSize = chunkSize ??
        QrTransferLimits.resolveChunkSize(
          sessionId: sessionId,
          fileBytes: fileBytes,
          chunkManager: _chunkManager,
        );

    final dataPackets = _chunkManager.split(
      data: fileBytes,
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
      fileSize: fileBytes.length,
      totalChunks: dataPackets.length,
      sha256: sha256,
      mimeType: mimeType,
    );

    TransferLimits.validateMetadata(
      fileName: metadata.fileName,
      fileSize: metadata.fileSize,
      totalChunks: metadata.totalChunks,
      sha256: metadata.sha256,
    );

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

    final session = TransferSession(
      id: sessionId,
      fileName: fileName,
      fileSize: fileBytes.length,
      totalChunks: dataPackets.length,
      sha256: sha256,
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

/// Bundle returned when preparing a sender session.
class SenderSessionBundle {
  const SenderSessionBundle({
    required this.session,
    required this.metadata,
    required this.dataPackets,
  });

  final TransferSession session;
  final MetadataPacket metadata;
  final List<DataPacket> dataPackets;

  List<TransferPacket> get allPackets => [metadata, ...dataPackets];
}
