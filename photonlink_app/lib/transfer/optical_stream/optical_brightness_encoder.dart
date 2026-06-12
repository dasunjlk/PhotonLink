import 'dart:typed_data';

import 'optical_pattern.dart';
import 'optical_stream_frame.dart';

/// Converts packet bytes into brightness cells (supports multi-bit density).
class OpticalBrightnessEncoder {
  const OpticalBrightnessEncoder({this.bitsPerCell = 3});

  final int bitsPerCell;

  List<BrightnessCell> encodeBytes(
    Uint8List frameBytes, {
    required int gridSize,
  }) {
    final maxCells = gridSize * gridSize;
    final bits = _bytesToBits(frameBytes);
    final cells = <BrightnessCell>[];

    for (var i = 0; i < maxCells; i++) {
      final startBit = i * bitsPerCell;
      if (startBit >= bits.length) {
        cells.add(const BrightnessCell(brightness: OpticalPattern.dark, bit: 0));
        continue;
      }
      var value = 0;
      final available = (bits.length - startBit).clamp(0, bitsPerCell);
      for (var b = 0; b < available; b++) {
        value = (value << 1) | bits[startBit + b];
      }
      value <<= (bitsPerCell - available);
      final maxVal = (1 << bitsPerCell) - 1;
      final brightness = maxVal == 0 ? 0.0 : value / maxVal;
      cells.add(BrightnessCell(brightness: brightness, bit: value & 1));
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
