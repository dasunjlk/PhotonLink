import 'dart:typed_data';

import '../../protocols/interfaces/compression_type.dart';
import 'compression_strategy.dart';

/// Pass-through compression (no-op).
class NoCompressionStrategy implements CompressionStrategy {
  const NoCompressionStrategy();

  @override
  CompressionType get type => CompressionType.none;

  @override
  Uint8List compress(Uint8List data) => data;

  @override
  Uint8List decompress(Uint8List data) => data;
}
