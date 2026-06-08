import 'dart:typed_data';

import 'color_matrix_frame.dart';
import 'color_palette.dart';

/// Validation result for a decoded color matrix frame.
class ColorDecodeResult {
  const ColorDecodeResult({
    required this.frameBytes,
    required this.valid,
    this.error,
  });

  final Uint8List frameBytes;
  final bool valid;
  final String? error;
}

/// Converts captured color cells back into packet bytes.
class ColorDecoder {
  const ColorDecoder({this.bitsPerChannel = 2});

  final int bitsPerChannel;

  int get bitsPerCell => bitsPerChannel * 3;

  /// Decodes [cells] from the data grid into raw frame bytes.
  ColorDecodeResult decodeCells(
    List<ColorCell> cells, {
    required int expectedByteLength,
  }) {
    final bits = <int>[];
    final neededBits = expectedByteLength * 8;

    for (final cell in cells) {
      final value = cell.value ??
          ColorPalette.rgbToCell(cell.r, cell.g, cell.b,
              bitsPerChannel: bitsPerChannel)
              .value ??
          0;
      for (var i = bitsPerCell - 1; i >= 0; i--) {
        bits.add((value >> i) & 1);
        if (bits.length >= neededBits) break;
      }
      if (bits.length >= neededBits) break;
    }

    while (bits.length < neededBits) {
      bits.add(0);
    }

    final bytes = Uint8List(expectedByteLength);
    for (var i = 0; i < expectedByteLength; i++) {
      var byte = 0;
      for (var b = 0; b < 8; b++) {
        byte = (byte << 1) | bits[i * 8 + b];
      }
      bytes[i] = byte;
    }

    return ColorDecodeResult(frameBytes: bytes, valid: true);
  }
}
