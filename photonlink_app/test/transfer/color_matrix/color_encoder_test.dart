import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/color_matrix/color_decoder.dart';
import 'package:photonlink_app/transfer/color_matrix/color_encoder.dart';

void main() {
  test('encode and decode bytes roundtrip', () {
    const encoder = ColorEncoder(bitsPerChannel: 2);
    const decoder = ColorDecoder(bitsPerChannel: 2);
    const gridSize = 16;

    final original = Uint8List.fromList([10, 20, 30, 40, 50]);
    final cells = encoder.encodeBytes(original, gridSize: gridSize);
    expect(cells.length, gridSize * gridSize);

    final result = decoder.decodeCells(cells, expectedByteLength: original.length);
    expect(result.valid, isTrue);
    expect(result.frameBytes, original);
  });
}
