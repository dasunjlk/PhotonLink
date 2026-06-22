import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'optical_pattern.dart';
import 'optical_stream_frame.dart';

/// Generates visual raster frames from encoded optical stream payloads.
class OpticalRenderer {
  const OpticalRenderer({
    this.imageSize = 320,
    this.marginCells = OpticalPattern.marginCells,
    this.showDebugOverlay = false,
  });

  final int imageSize;
  final int marginCells;
  final bool showDebugOverlay;

  /// Renders [frame] to PNG bytes for display.
  Uint8List generateRaster(OpticalStreamFrame frame) {
    final gridSize = frame.gridSize;
    final totalCells = gridSize + marginCells * 2;
    final cellPx = imageSize ~/ totalCells;
    final image = img.Image(width: imageSize, height: imageSize);

    img.fill(image, color: img.ColorRgb8(32, 32, 32));

    _paintSyncBorder(image, totalCells, cellPx);
    _paintTimingLanes(image, totalCells, cellPx);
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
        final cell = OpticalPattern.syncCell(row, col);
        _fillCell(image, col, row, cellPx, cell);
      }
    }
  }

  void _paintTimingLanes(img.Image image, int totalCells, int cellPx) {
    for (var i = 0; i < totalCells; i++) {
      final cell = OpticalPattern.timingCell(i);
      _fillCell(image, i, marginCells, cellPx, cell);
      _fillCell(image, marginCells, i, cellPx, cell);
    }
  }

  void _paintOrientationMarkers(img.Image image, int totalCells, int cellPx) {
    final m = OpticalPattern.markerSize;
    _paintMarkerBlock(
      image,
      0,
      0,
      m,
      cellPx,
      OpticalPattern.topLeftMarker,
    );
    _paintMarkerBlock(
      image,
      totalCells - m,
      0,
      m,
      cellPx,
      OpticalPattern.topRightMarker,
    );
    _paintMarkerBlock(
      image,
      0,
      totalCells - m,
      m,
      cellPx,
      OpticalPattern.bottomLeftMarker,
    );
    _paintMarkerBlock(
      image,
      totalCells - m,
      totalCells - m,
      m,
      cellPx,
      OpticalPattern.bottomRightMarker,
    );
  }

  void _paintMarkerBlock(
    img.Image image,
    int col,
    int row,
    int size,
    int cellPx,
    BrightnessCell cell,
  ) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        _fillCell(image, col + c, row + r, cellPx, cell);
      }
    }
  }

  void _paintDataCells(
    img.Image image,
    List<BrightnessCell> cells,
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
    BrightnessCell cell,
  ) {
    final gray = (cell.brightness * 255).round().clamp(0, 255);
    final x0 = col * cellPx;
    final y0 = row * cellPx;
    for (var y = y0; y < y0 + cellPx && y < imageSize; y++) {
      for (var x = x0; x < x0 + cellPx && x < imageSize; x++) {
        image.setPixelRgb(x, y, gray, gray, gray);
      }
    }
  }

  void _paintDebugOverlay(img.Image image, OpticalStreamFrame frame) {
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
