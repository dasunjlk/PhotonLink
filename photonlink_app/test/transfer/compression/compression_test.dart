import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/compression/compression_manager.dart';
import 'package:photonlink_app/protocols/interfaces/compression_type.dart';

void main() {
  test('gzip compresses and decompresses', () {
    const manager = CompressionManager();
    final original = Uint8List.fromList(List.generate(500, (i) => i % 256));

    final compressed =
        manager.strategyFor(CompressionType.gzip).compress(original);
    expect(compressed.length, lessThan(original.length));

    final restored =
        manager.strategyFor(CompressionType.gzip).decompress(compressed);
    expect(restored, original);
  });

  test('none strategy is identity', () {
    const manager = CompressionManager();
    final original = Uint8List.fromList([1, 2, 3]);
    final strategy = manager.strategyFor(CompressionType.none);
    expect(strategy.compress(original), original);
    expect(strategy.decompress(original), original);
  });
}
