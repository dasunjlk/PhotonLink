import '../../protocols/interfaces/compression_type.dart';
import 'compression_strategy.dart';
import 'gzip_compression_strategy.dart';
import 'no_compression_strategy.dart';

/// Selects and applies compression strategies.
class CompressionManager {
  const CompressionManager();

  static const NoCompressionStrategy _none = NoCompressionStrategy();
  static const GzipCompressionStrategy _gzip = GzipCompressionStrategy();

  CompressionStrategy strategyFor(CompressionType type) {
    switch (type) {
      case CompressionType.none:
        return _none;
      case CompressionType.gzip:
        return _gzip;
    }
  }
}
