import 'dart:typed_data';

import 'chunk_manager.dart';
import 'transfer_encoder.dart';
import 'transfer_packet.dart';

/// Transport-specific frame capacity probing and chunk sizing.
abstract interface class TransportLimitsResolver<TFrame> {
  /// Human-readable transport label for error messages.
  String get transportLabel;

  /// Maximum file size accepted for this transport.
  int get maxFileBytes;

  /// Picks the largest chunk size that keeps all encoded frames within limits.
  int resolveChunkSize({
    required String sessionId,
    required Uint8List fileBytes,
    required ChunkManager chunkManager,
    required TransferEncoder<TFrame> encoder,
  });

  /// Returns true if metadata and all data frames encode within transport limits.
  bool allFramesFit({
    required String sessionId,
    required MetadataPacket metadata,
    required List<DataPacket> dataPackets,
    required TransferEncoder<TFrame> encoder,
  });
}
