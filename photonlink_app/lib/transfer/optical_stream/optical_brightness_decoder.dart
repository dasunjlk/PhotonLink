import 'dart:typed_data';

import 'optical_stream_frame.dart';

/// Validation result for a decoded optical stream frame.
class OpticalDecodeResult {
  const OpticalDecodeResult({
    required this.frameBytes,
    required this.valid,
    this.error,
  });

  final Uint8List frameBytes;
  final bool valid;
  final String? error;
}

/// Converts captured brightness cells back into packet bytes.
class OpticalBrightnessDecoder {
  const OpticalBrightnessDecoder({this.bitsPerCell = 3});

  final int bitsPerCell;

  OpticalDecodeResult decodeCells(
    List<BrightnessCell> cells, {
    required int expectedByteLength,
  }) {
    final bits = <int>[];
    final neededBits = expectedByteLength * 8;
    final maxVal = (1 << bitsPerCell) - 1;

    for (final cell in cells) {
      var value = cell.bit ?? (cell.brightness >= 0.5 ? 1 : 0);
      if (bitsPerCell > 1) {
        value = (cell.brightness * maxVal).round().clamp(0, maxVal);
      }
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

    return OpticalDecodeResult(frameBytes: bytes, valid: true);
  }
}
