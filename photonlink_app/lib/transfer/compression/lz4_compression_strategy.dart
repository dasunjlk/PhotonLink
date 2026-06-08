import '../../protocols/interfaces/compression_type.dart';
import 'compression_strategy.dart';
import 'models/compression_result.dart';

/// LZ4 placeholder — disabled until Rust core or FFI is available.
class Lz4CompressionStrategy implements CompressionStrategy {
  const Lz4CompressionStrategy();

  @override
  CompressionType get type => CompressionType.lz4;

  @override
  bool get isEnabled => false;

  @override
  CompressionResult compress(List<int> input) {
    throw UnsupportedError('LZ4 compression is not enabled in this build');
  }

  @override
  CompressionResult decompress(List<int> input, {required int originalSize}) {
    throw UnsupportedError('LZ4 decompression is not enabled in this build');
  }
}
