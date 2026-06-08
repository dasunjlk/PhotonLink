import 'dart:typed_data';

import '../../protocols/interfaces/compression_type.dart';

/// Compresses and decompresses file payloads before chunking.
abstract interface class CompressionStrategy {
  CompressionType get type;
  Uint8List compress(Uint8List data);
  Uint8List decompress(Uint8List data);
}
