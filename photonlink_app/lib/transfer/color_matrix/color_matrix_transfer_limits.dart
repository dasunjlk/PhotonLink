import 'dart:typed_data';

import '../../protocols/interfaces/chunk_manager.dart';
import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transport_limits_resolver.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../core/transfer_limits.dart';
import 'color_matrix_frame.dart';
import 'color_matrix_frame_codec.dart';

/// Color Matrix-specific frame size calculations and validation.
abstract final class ColorMatrixTransferLimits {
  static bool allFramesFit({
    required String sessionId,
    required MetadataPacket metadata,
    required List<DataPacket> dataPackets,
    required ColorMatrixFrameCodec encoder,
  }) {
    try {
      encoder.resetFrameCounter();
      final metaFrame = encoder.encodeFrame(metadata);
      if (!_frameValid(metaFrame)) return false;

      for (final packet in dataPackets) {
        final frame = encoder.encodeFrame(packet);
        if (!_frameValid(frame)) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _frameValid(ColorMatrixFrame frame) {
    return frame.cells.length == frame.gridSize * frame.gridSize;
  }

  static int resolveChunkSize({
    required String sessionId,
    required Uint8List fileBytes,
    required ChunkManager chunkManager,
    required ColorMatrixFrameCodec encoder,
  }) {
    var chunkSize = ChunkManager.defaultChunkSize * 4;
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
      encoder.resetFrameCounter();
      if (allFramesFit(
        sessionId: sessionId,
        metadata: metadata,
        dataPackets: packets,
        encoder: encoder,
      )) {
        return chunkSize;
      }
      chunkSize ~/= 2;
    }
    throw TransferLimitException(
      'File cannot be encoded into Color Matrix frames',
    );
  }
}

/// Color Matrix [TransportLimitsResolver] implementation.
class ColorMatrixTransferLimitsResolver
    implements TransportLimitsResolver<ColorMatrixFrame> {
  ColorMatrixTransferLimitsResolver({
    this.gridSize = 16,
    this.bitsPerChannel = 2,
  });

  final int gridSize;
  final int bitsPerChannel;

  @override
  String get transportLabel => 'Color Matrix transfer';

  @override
  int get maxFileBytes => TransferLimits.maxColorMatrixFileBytes;

  @override
  int resolveChunkSize({
    required String sessionId,
    required Uint8List fileBytes,
    required ChunkManager chunkManager,
    required TransferEncoder<ColorMatrixFrame> encoder,
  }) {
    return ColorMatrixTransferLimits.resolveChunkSize(
      sessionId: sessionId,
      fileBytes: fileBytes,
      chunkManager: chunkManager,
      encoder: encoder as ColorMatrixFrameCodec,
    );
  }

  @override
  bool allFramesFit({
    required String sessionId,
    required MetadataPacket metadata,
    required List<DataPacket> dataPackets,
    required TransferEncoder<ColorMatrixFrame> encoder,
  }) {
    return ColorMatrixTransferLimits.allFramesFit(
      sessionId: sessionId,
      metadata: metadata,
      dataPackets: dataPackets,
      encoder: encoder as ColorMatrixFrameCodec,
    );
  }
}
