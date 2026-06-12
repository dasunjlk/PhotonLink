import '../../protocols/interfaces/compression_type.dart';
import '../../transfer/compression/models/compression_result.dart';

/// Compression operations (Phase 8B).
abstract interface class CompressionService {
  CompressionResult compress(List<int> input, CompressionType type);
  CompressionResult decompress(
    List<int> input, {
    required CompressionType type,
    required int originalSize,
  });
}
