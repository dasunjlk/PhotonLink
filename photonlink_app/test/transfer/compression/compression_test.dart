import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/compression_type.dart';
import 'package:photonlink_app/transfer/compression/compression_manager.dart';
import 'package:photonlink_app/transfer/compression/lz4_compression_strategy.dart';

void main() {
  final manager = CompressionManager();

  test('gzip roundtrip', () {
    final input = List<int>.generate(500, (i) => i % 256);
    final compressed = manager.compress(input, CompressionType.gzip);
    expect(compressed.outputSize, lessThan(input.length));
    final restored = manager.decompress(
      compressed.bytes,
      type: CompressionType.gzip,
      originalSize: input.length,
    );
    expect(restored.bytes, input);
  });

  test('no compression identity', () {
    final input = Uint8List.fromList([1, 2, 3]);
    final out = manager.compress(input, CompressionType.none);
    expect(out.bytes, input);
  });

  test('lz4 placeholder disabled', () {
    expect(const Lz4CompressionStrategy().isEnabled, isFalse);
    expect(
      () => manager.compress([1], CompressionType.lz4),
      throwsUnsupportedError,
    );
  });
}
