import 'dart:io';

import '../../protocols/interfaces/compression_type.dart';
import 'compression_strategy.dart';
import 'models/compression_result.dart';

/// GZip compression via dart:io (active Phase 4 codec).
class GzipCompressionStrategy implements CompressionStrategy {
  const GzipCompressionStrategy();

  @override
  CompressionType get type => CompressionType.gzip;

  @override
  bool get isEnabled => true;

  @override
  CompressionResult compress(List<int> input) {
    final compressed = GZipCodec().encode(input);
    return CompressionResult(
      type: type,
      originalSize: input.length,
      outputSize: compressed.length,
      bytes: compressed,
    );
  }

  @override
  CompressionResult decompress(List<int> input, {required int originalSize}) {
    final decompressed = GZipCodec().decode(input);
    return CompressionResult(
      type: type,
      originalSize: originalSize,
      outputSize: decompressed.length,
      bytes: decompressed,
    );
  }
}
