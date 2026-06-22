import 'dart:typed_data';

import '../../core/constants.dart';
import '../../protocols/interfaces/chunk_manager.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transport_limits_resolver.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../core/transfer_limits.dart';
import 'optical_stream_frame.dart';
import 'optical_stream_codec.dart';

/// Optical Stream-specific frame size calculations and validation.
abstract final class OpticalStreamTransferLimits {
  static const List<int> gridSizes = [16, 24, 32, 48];

  static int serializedCapacity({
    required int gridSize,
    required int bitsPerCell,
  }) {
    return gridSize * gridSize * bitsPerCell ~/ 8;
  }

  static int resolveViableGrid({
    required String sessionId,
    required String fileName,
    required int fileSize,
    required int bitsPerCell,
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
      final codec = OpticalStreamFrameCodec(
        gridSize: grid,
        bitsPerCell: bitsPerCell,
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
      'File cannot be encoded into Optical Stream frames. '
      'Try a shorter file name or increase grid size in Settings.',
    );
  }

  static bool allFramesFit({
    required String sessionId,
    required MetadataPacket metadata,
    required List<DataPacket> dataPackets,
    required OpticalStreamFrameCodec encoder,
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

  static bool _frameValid(OpticalStreamFrame frame) {
    return frame.cells.length == frame.gridSize * frame.gridSize;
  }

  static bool _metadataEncodes(
    OpticalStreamFrameCodec codec,
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
    required OpticalStreamFrameCodec encoder,
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
      'File cannot be encoded into Optical Stream frames. '
      'Try enabling compression or using a smaller file.',
    );
  }
}

/// Optical Stream [TransportLimitsResolver] implementation.
class OpticalStreamTransferLimitsResolver
    implements TransportLimitsResolver<OpticalStreamFrame> {
  OpticalStreamTransferLimitsResolver({
    this.gridSize = 24,
    this.bitsPerCell = 1,
  });

  final int gridSize;
  final int bitsPerCell;

  @override
  String get transportLabel => 'Optical Stream transfer';

  @override
  int get maxFileBytes => TransferLimits.maxOpticalStreamFileBytes;

  @override
  int resolveChunkSize({
    required String sessionId,
    required Uint8List fileBytes,
    required ChunkManager chunkManager,
    required TransferEncoder<OpticalStreamFrame> encoder,
  }) {
    return OpticalStreamTransferLimits.resolveChunkSize(
      sessionId: sessionId,
      fileBytes: fileBytes,
      chunkManager: chunkManager,
      encoder: encoder as OpticalStreamFrameCodec,
      fileName: '_probe_',
    );
  }

  @override
  bool allFramesFit({
    required String sessionId,
    required MetadataPacket metadata,
    required List<DataPacket> dataPackets,
    required TransferEncoder<OpticalStreamFrame> encoder,
  }) {
    return OpticalStreamTransferLimits.allFramesFit(
      sessionId: sessionId,
      metadata: metadata,
      dataPackets: dataPackets,
      encoder: encoder as OpticalStreamFrameCodec,
    );
  }
}
