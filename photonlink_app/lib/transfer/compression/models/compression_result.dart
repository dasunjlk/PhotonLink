import '../../../protocols/interfaces/compression_type.dart';

/// Result of compressing or decompressing a payload.
class CompressionResult {
  const CompressionResult({
    required this.type,
    required this.originalSize,
    required this.outputSize,
    required this.bytes,
  });

  final CompressionType type;
  final int originalSize;
  final int outputSize;
  final List<int> bytes;

  double get ratio =>
      originalSize > 0 ? outputSize / originalSize : 1.0;

  int get savingsBytes => originalSize - outputSize;

  double get savingsPercent =>
      originalSize > 0 ? (savingsBytes / originalSize) * 100 : 0;
}
