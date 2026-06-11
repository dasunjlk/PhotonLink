import 'dart:typed_data';

import '../../core/constants.dart';
import '../../protocols/interfaces/chunk_manager.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transport_limits_resolver.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../core/transfer_limits.dart';
import 'color_matrix_frame.dart';
import 'color_matrix_frame_codec.dart';

/// Color Matrix-specific frame size calculations and validation.
abstract final class ColorMatrixTransferLimits {
  static const List<int> gridSizes = [16, 24, 32, 48];

  /// Serialized byte capacity for a grid at the given density.
  static int serializedCapacity({
    required int gridSize,
    required int bitsPerChannel,
  }) {
    return gridSize * gridSize * bitsPerChannel * 3 ~/ 8;
  }

  /// Smallest grid that can encode realistic session metadata (long file names).
  static int resolveViableGrid({
    required String sessionId,
    required String fileName,
    required int fileSize,
    required int bitsPerChannel,
    CompressionType compression = CompressionType.none,
    EncryptionMode encryption = EncryptionMode.disabled,
    int? originalSize,
    String? originalSha256,
    String? keyExchangePayload,
    int preferredGrid = 24,
  }) {
    final candidates = <int>{
      preferredGrid,
      ...gridSizes,
    }.where((g) => gridSizes.contains(g)).toList()
      ..sort();

    for (final grid in candidates) {
      final codec = ColorMatrixFrameCodec(
        gridSize: grid,
        bitsPerChannel: bitsPerChannel,
      );
      codec.encoderKeyExchangePayload = keyExchangePayload;
      if (_metadataEncodes(
        codec,
        MetadataPacket(
          sessionId: sessionId,
          fileName: fileName,
          fileSize: fileSize,
          totalChunks: 1,
          sha256: '0' * 64,
          mimeType: 'application/octet-stream',
          protocolVersion: AppConstants.protocolVersion,
          compression: compression,
          encryption: encryption,
          originalSize: originalSize,
          originalSha256: originalSha256,
        ),
      )) {
        return grid;
      }
    }

    throw TransferLimitException(
      'File cannot be encoded into Color Matrix frames. '
      'The file name or session metadata is too large for the current grid '
      '($preferredGrid×$preferredGrid, $bitsPerChannel bits/channel). '
      'Try a shorter file name or set a larger Color Matrix grid in Settings.',
    );
  }

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

  static bool _metadataEncodes(
    ColorMatrixFrameCodec codec,
    MetadataPacket metadata,
  ) {
    try {
      final frame = codec.encodeFrame(metadata);
      return _frameValid(frame);
    } catch (_) {
      return false;
    }
  }

  static int resolveChunkSize({
    required String sessionId,
    required Uint8List fileBytes,
    required ChunkManager chunkManager,
    required ColorMatrixFrameCodec encoder,
    required String fileName,
    CompressionType compression = CompressionType.none,
    EncryptionMode encryption = EncryptionMode.disabled,
    int? originalSize,
    String? originalSha256,
    String? keyExchangePayload,
  }) {
    var chunkSize = ChunkManager.defaultChunkSize * 4;
    while (chunkSize >= TransferLimits.minChunkSize) {
      final packets = chunkManager.split(
        data: fileBytes,
        sessionId: sessionId,
        chunkSize: chunkSize,
      );
      encoder.encoderKeyExchangePayload = keyExchangePayload;
      final metadata = MetadataPacket(
        sessionId: sessionId,
        fileName: fileName,
        fileSize: fileBytes.length,
        totalChunks: packets.length,
        sha256: '0' * 64,
        mimeType: 'application/octet-stream',
        protocolVersion: AppConstants.protocolVersion,
        compression: compression,
        encryption: encryption,
        originalSize: originalSize,
        originalSha256: originalSha256,
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
      'File cannot be encoded into Color Matrix frames. '
      'Try enabling compression, using a smaller file, or increasing the '
      'Color Matrix grid size in Settings.',
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
      fileName: '_probe_',
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
