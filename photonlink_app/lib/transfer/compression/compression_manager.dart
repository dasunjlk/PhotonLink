import '../../protocols/interfaces/compression_type.dart';
import 'compression_strategy.dart';
import 'gzip_compression_strategy.dart';
import 'lz4_compression_strategy.dart';
import 'models/compression_result.dart';
import 'no_compression_strategy.dart';

/// Selects and applies compression strategies (transport-agnostic).
class CompressionManager {
  CompressionManager({
    CompressionStrategy? none,
    CompressionStrategy? gzip,
    CompressionStrategy? lz4,
  })  : _strategies = {
          CompressionType.none: none ?? const NoCompressionStrategy(),
          CompressionType.gzip: gzip ?? const GzipCompressionStrategy(),
          CompressionType.lz4: lz4 ?? const Lz4CompressionStrategy(),
        };

  final Map<CompressionType, CompressionStrategy> _strategies;

  CompressionStrategy strategyFor(CompressionType type) {
    final s = _strategies[type]!;
    if (!s.isEnabled && type != CompressionType.none) {
      throw UnsupportedError('Compression $type is not enabled');
    }
    return s;
  }

  CompressionResult compress(List<int> input, CompressionType type) {
    return strategyFor(type).compress(input);
  }

  CompressionResult decompress(
    List<int> input, {
    required CompressionType type,
    required int originalSize,
  }) {
    return strategyFor(type).decompress(input, originalSize: originalSize);
  }
}
