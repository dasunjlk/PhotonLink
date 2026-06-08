import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'color_matrix_frame.dart';
import 'color_palette.dart';

/// Orientation marker colors for corner identification.
abstract final class OrientationMarkers {
  static const ColorCell topLeft = ColorCell(r: 255, g: 0, b: 0);
  static const ColorCell topRight = ColorCell(r: 0, g: 255, b: 0);
  static const ColorCell bottomLeft = ColorCell(r: 0, g: 0, b: 255);
  static const ColorCell bottomRight = ColorCell(r: 255, g: 255, b: 0);

  static const int markerSize = 3;
}

/// Sync border pattern colors.
abstract final class SyncMarkers {
  static const ColorCell light = ColorCell(r: 255, g: 255, b: 255);
  static const ColorCell dark = ColorCell(r: 0, g: 0, b: 0);
}

/// Generates visual raster frames from encoded color matrix payloads.
class ColorFrameGenerator {
  const ColorFrameGenerator({
    this.imageSize = 320,
    this.marginCells = 2,
    this.showDebugOverlay = false,
  });

  final int imageSize;
  final int marginCells;
  final bool showDebugOverlay;

  /// Renders [frame] to PNG bytes for display.
  Uint8List generateRaster(ColorMatrixFrame frame) {
    final gridSize = frame.gridSize;
    final totalCells = gridSize + marginCells * 2;
    final cellPx = imageSize ~/ totalCells;
    final image = img.Image(width: imageSize, height: imageSize);

    img.fill(image, color: img.ColorRgb8(32, 32, 32));

    _paintSyncBorder(image, totalCells, cellPx);
    _paintOrientationMarkers(image, totalCells, cellPx);
    _paintDataCells(image, frame.cells, gridSize, cellPx);

    if (showDebugOverlay) {
      _paintDebugOverlay(image, frame);
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  void _paintSyncBorder(img.Image image, int totalCells, int cellPx) {
    for (var row = 0; row < totalCells; row++) {
      for (var col = 0; col < totalCells; col++) {
        final isBorder = row < marginCells ||
            row >= totalCells - marginCells ||
            col < marginCells ||
            col >= totalCells - marginCells;
        if (!isBorder) continue;
        final isLight = (row + col) % 2 == 0;
        final color = isLight ? SyncMarkers.light : SyncMarkers.dark;
        _fillCell(image, col, row, cellPx, color);
      }
    }
  }

  void _paintOrientationMarkers(img.Image image, int totalCells, int cellPx) {
    final m = OrientationMarkers.markerSize;
    _paintMarkerBlock(image, 0, 0, m, cellPx, OrientationMarkers.topLeft);
    _paintMarkerBlock(
      image,
      totalCells - m,
      0,
      m,
      cellPx,
      OrientationMarkers.topRight,
    );
    _paintMarkerBlock(
      image,
      0,
      totalCells - m,
      m,
      cellPx,
      OrientationMarkers.bottomLeft,
    );
    _paintMarkerBlock(
      image,
      totalCells - m,
      totalCells - m,
      m,
      cellPx,
      OrientationMarkers.bottomRight,
    );
  }

  void _paintMarkerBlock(
    img.Image image,
    int col,
    int row,
    int size,
    int cellPx,
    ColorCell color,
  ) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        _fillCell(image, col + c, row + r, cellPx, color);
      }
    }
  }

  void _paintDataCells(
    img.Image image,
    List<ColorCell> cells,
    int gridSize,
    int cellPx,
  ) {
    for (var i = 0; i < cells.length && i < gridSize * gridSize; i++) {
      final row = i ~/ gridSize;
      final col = i % gridSize;
      _fillCell(
        image,
        col + marginCells,
        row + marginCells,
        cellPx,
        cells[i],
      );
    }
  }

  void _fillCell(
    img.Image image,
    int col,
    int row,
    int cellPx,
    ColorCell color,
  ) {
    final x0 = col * cellPx;
    final y0 = row * cellPx;
    for (var y = y0; y < y0 + cellPx && y < imageSize; y++) {
      for (var x = x0; x < x0 + cellPx && x < imageSize; x++) {
        image.setPixelRgb(x, y, color.r, color.g, color.b);
      }
    }
  }

  void _paintDebugOverlay(img.Image image, ColorMatrixFrame frame) {
    // Frame ID encoded as top row pixel tint after data grid
    final tint = frame.frameId % 256;
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, 0);
      image.setPixelRgb(
        x,
        0,
        (p.r.toInt() + tint) % 256,
        p.g.toInt(),
        p.b.toInt(),
      );
    }
  }
}
