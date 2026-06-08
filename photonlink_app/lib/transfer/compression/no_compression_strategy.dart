import 'dart:typed_data';

import '../../protocols/interfaces/compression_type.dart';
import 'compression_strategy.dart';
import 'models/compression_result.dart';

/// Pass-through compression (identity).
class NoCompressionStrategy implements CompressionStrategy {
  const NoCompressionStrategy();

  @override
  CompressionType get type => CompressionType.none;

  @override
  bool get isEnabled => true;

  @override
  CompressionResult compress(List<int> input) {
    return CompressionResult(
      type: type,
      originalSize: input.length,
      outputSize: input.length,
      bytes: Uint8List.fromList(input),
    );
  }

  @override
  CompressionResult decompress(List<int> input, {required int originalSize}) {
    return CompressionResult(
      type: type,
      originalSize: originalSize,
      outputSize: input.length,
      bytes: Uint8List.fromList(input),
    );
  }
}
