import 'dart:typed_data';

import 'color_matrix_frame.dart';
import 'color_palette.dart';

/// Converts packet bytes into deterministic RGB color cells.
class ColorEncoder {
  const ColorEncoder({this.bitsPerChannel = 2});

  final int bitsPerChannel;

  int get bitsPerCell => bitsPerChannel * 3;

  /// Encodes [frameBytes] into a list of [ColorCell]s for the data grid.
  List<ColorCell> encodeBytes(Uint8List frameBytes, {required int gridSize}) {
    final maxCells = gridSize * gridSize;
    final bits = _bytesToBits(frameBytes);
    final cells = <ColorCell>[];

    for (var i = 0; i < maxCells; i++) {
      final startBit = i * bitsPerCell;
      if (startBit >= bits.length) {
        cells.add(const ColorCell(r: 0, g: 0, b: 0, value: 0));
        continue;
      }
      var value = 0;
      final available = (bits.length - startBit).clamp(0, bitsPerCell);
      for (var b = 0; b < available; b++) {
        value = (value << 1) | bits[startBit + b];
      }
      value <<= (bitsPerCell - available);
      cells.add(ColorPalette.valueToCell(value, bitsPerChannel: bitsPerChannel));
    }

    return cells;
  }

  List<int> _bytesToBits(Uint8List bytes) {
    final bits = <int>[];
    for (final byte in bytes) {
      for (var i = 7; i >= 0; i--) {
        bits.add((byte >> i) & 1);
      }
    }
    return bits;
  }
}
