import 'color_matrix_frame.dart';

/// Deterministic RGB palette for robust camera capture.
abstract final class ColorPalette {
  /// Quantized channel levels for [bitsPerChannel] bits (default 2 → 4 levels).
  static List<int> channelLevels(int bitsPerChannel) {
    final levels = 1 << bitsPerChannel;
    return List.generate(
      levels,
      (i) => ((255 * i) / (levels - 1)).round(),
    );
  }

  /// Maps a 6-bit cell value to RGB using 2 bits per channel.
  static ColorCell valueToCell(int value, {int bitsPerChannel = 2}) {
    final mask = (1 << bitsPerChannel) - 1;
    final rBits = (value >> (bitsPerChannel * 2)) & mask;
    final gBits = (value >> bitsPerChannel) & mask;
    final bBits = value & mask;
    final levels = channelLevels(bitsPerChannel);
    return ColorCell(
      r: levels[rBits.clamp(0, levels.length - 1)],
      g: levels[gBits.clamp(0, levels.length - 1)],
      b: levels[bBits.clamp(0, levels.length - 1)],
      value: value,
    );
  }

  /// Nearest palette cell for captured RGB.
  static ColorCell rgbToCell(int r, int g, int b, {int bitsPerChannel = 2}) {
    final levels = channelLevels(bitsPerChannel);
    int quantize(int channel) {
      var best = levels.first;
      var bestDist = (channel - best).abs();
      for (final level in levels) {
        final dist = (channel - level).abs();
        if (dist < bestDist) {
          bestDist = dist;
          best = level;
        }
      }
      return best;
    }

    final rq = quantize(r);
    final gq = quantize(g);
    final bq = quantize(b);

    int bitsFor(int quantized) {
      var bestIdx = 0;
      var bestDist = (quantized - levels[0]).abs();
      for (var i = 1; i < levels.length; i++) {
        final dist = (quantized - levels[i]).abs();
        if (dist < bestDist) {
          bestDist = dist;
          bestIdx = i;
        }
      }
      return bestIdx;
    }

    final rBits = bitsFor(rq);
    final gBits = bitsFor(gq);
    final bBits = bitsFor(bq);
    final value = (rBits << (bitsPerChannel * 2)) |
        (gBits << bitsPerChannel) |
        bBits;

    return ColorCell(r: rq, g: gq, b: bq, value: value);
  }

  static int maxCellValue(int bitsPerChannel) =>
      (1 << (bitsPerChannel * 3)) - 1;
}
