import 'dart:typed_data';

import '../../protocols/interfaces/chunk_manager.dart';
import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../core/transfer_limits.dart';
import 'qr_frame_codec.dart';

/// QR-specific frame size calculations and validation.
abstract final class QrTransferLimits {
  /// Estimates max raw chunk bytes that fit in a data QR frame.
  static int maxDataPayloadBytes({
    required String sessionId,
    required int totalChunks,
    required int chunkId,
  }) {
    final header =
        '${QrFrameCodec.magic}|D|$sessionId|$chunkId|$totalChunks|';
    final overhead = header.length;
    final maxBase64Chars = TransferLimits.maxQrFrameChars - overhead;
    if (maxBase64Chars <= 0) return 0;
    return (maxBase64Chars * 3 ~/ 4) - 8;
  }

  /// Returns true if every data frame encodes within [TransferLimits.maxQrFrameChars].
  static bool allDataFramesFit(
    String sessionId,
    MetadataPacket metadata,
    List<DataPacket> dataPackets,
    TransferEncoder encoder,
  ) {
    for (final packet in dataPackets) {
      final frame = encoder.encodeFrame(packet);
      if (frame.length > TransferLimits.maxQrFrameChars) {
        return false;
      }
    }
    final metaFrame = encoder.encodeFrame(metadata);
    return metaFrame.length <= TransferLimits.maxQrFrameChars;
  }

  /// Picks the largest chunk size that keeps all encoded data frames under the limit.
  static int resolveChunkSize({
    required String sessionId,
    required Uint8List fileBytes,
    required ChunkManager chunkManager,
    TransferEncoder encoder = const QrFrameCodec(),
  }) {
    var chunkSize = ChunkManager.defaultChunkSize;
    while (chunkSize >= TransferLimits.minChunkSize) {
      final packets = chunkManager.split(
        data: fileBytes,
        sessionId: sessionId,
        chunkSize: chunkSize,
      );
      final metadata = MetadataPacket(
        sessionId: sessionId,
        fileName: '_probe_',
        fileSize: fileBytes.length,
        totalChunks: packets.length,
        sha256: '0' * 64,
        mimeType: 'application/octet-stream',
      );
      if (allDataFramesFit(sessionId, metadata, packets, encoder)) {
        return chunkSize;
      }
      chunkSize ~/= 2;
    }
    throw TransferLimitException(
      'File cannot be encoded into scannable QR frames',
    );
  }
}
