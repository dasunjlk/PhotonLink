import 'dart:typed_data';

import 'transfer_packet.dart';

/// Splits file bytes into chunks and merges them back.
abstract interface class ChunkManager {
  /// Default chunk size tuned for QR capacity with Base64 overhead.
  static const int defaultChunkSize = 512;

  List<DataPacket> split({
    required Uint8List data,
    required String sessionId,
    int chunkSize = defaultChunkSize,
  });

  Uint8List merge(List<DataPacket> packets);
}
