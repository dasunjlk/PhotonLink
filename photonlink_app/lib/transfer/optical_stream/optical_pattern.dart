import 'optical_stream_frame.dart';

/// Sync lane and finder pattern constants for optical stream grids.
abstract final class OpticalPattern {
  static const int marginCells = 2;
  static const int markerSize = 3;

  /// Binary brightness levels (future multi-level density upgrades use more).
  static const double light = 1.0;
  static const double dark = 0.0;

  /// Corner finder patterns (unique per corner for orientation).
  static const BrightnessCell topLeftMarker =
      BrightnessCell(brightness: light, bit: 1);
  static const BrightnessCell topRightMarker =
      BrightnessCell(brightness: dark, bit: 0);
  static const BrightnessCell bottomLeftMarker =
      BrightnessCell(brightness: dark, bit: 0);
  static const BrightnessCell bottomRightMarker =
      BrightnessCell(brightness: light, bit: 1);

  /// Sync border alternation for grid lock.
  static BrightnessCell syncCell(int row, int col) {
    return BrightnessCell(
      brightness: (row + col) % 2 == 0 ? light : dark,
      bit: (row + col) % 2,
    );
  }

  /// Timing lane calibration cell (row/col edge).
  static BrightnessCell timingCell(int index) {
    return BrightnessCell(
      brightness: index % 2 == 0 ? light : dark,
      bit: index % 2,
    );
  }

  /// Payload lane cell from raw bit.
  static BrightnessCell payloadCell(int bit) {
    return BrightnessCell(
      brightness: bit == 1 ? light : dark,
      bit: bit,
    );
  }

  /// Maximum serialized bytes that fit in a grid at given density.
  static int maxPayloadBytes(int gridSize, int bitsPerCell) {
    final totalBits = gridSize * gridSize * bitsPerCell;
    return totalBits ~/ 8;
  }
}
