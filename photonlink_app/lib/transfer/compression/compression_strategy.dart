import '../../protocols/interfaces/compression_type.dart';
import 'models/compression_result.dart';

/// Transport-agnostic compression codec.
abstract interface class CompressionStrategy {
  CompressionType get type;

  bool get isEnabled;

  CompressionResult compress(List<int> input);

  CompressionResult decompress(List<int> input, {required int originalSize});
}
