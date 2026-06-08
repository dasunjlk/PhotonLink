import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'color_matrix_frame.dart';
import 'color_palette.dart';
import 'color_frame_generator.dart';

/// Result of detecting a color matrix in a camera frame.
class ColorDetectionResult {
  const ColorDetectionResult({
    required this.cells,
    required this.gridSize,
    required this.detected,
    required this.accuracy,
    this.orientation = 0,
  });

  final List<ColorCell> cells;
  final int gridSize;
  final bool detected;
  final double accuracy;
  final int orientation;
}

/// Detects color matrix grids in captured camera frames.
class ColorFrameDetector {
  const ColorFrameDetector({
    this.defaultGridSize = 16,
    this.marginCells = 2,
  });

  final int defaultGridSize;
  final int marginCells;

  /// Detects and extracts data cells from [imageBytes] (PNG/JPEG/raw RGB).
  ColorDetectionResult detect(Uint8List imageBytes, {int? gridSize}) {
    final grid = gridSize ?? defaultGridSize;
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      return const ColorDetectionResult(
        cells: [],
        gridSize: 16,
        detected: false,
        accuracy: 0,
      );
    }

    final corners = _findCorners(image);
    if (corners == null) {
      return ColorDetectionResult(
        cells: [],
        gridSize: grid,
        detected: false,
        accuracy: 0,
      );
    }

    final cells = _sampleGrid(image, corners, grid);
    final accuracy = _estimateAccuracy(cells);

    return ColorDetectionResult(
      cells: cells,
      gridSize: grid,
      detected: cells.isNotEmpty,
      accuracy: accuracy,
    );
  }

  /// Detects from a raw RGB buffer (width x height).
  ColorDetectionResult detectFromRgb({
    required Uint8List rgbBytes,
    required int width,
    required int height,
    int? gridSize,
  }) {
    final grid = gridSize ?? defaultGridSize;
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgbBytes.buffer,
      numChannels: 3,
      order: img.ChannelOrder.rgb,
    );
    return detect(Uint8List.fromList(img.encodePng(image)), gridSize: grid);
  }

  List<_Point>? _findCorners(img.Image image) {
    // Search corners for orientation marker colors
    final w = image.width;
    final h = image.height;
    final margin = (w * 0.05).round();

    final tl = _findMarkerNear(image, 0, 0, margin, OrientationMarkers.topLeft);
    final tr = _findMarkerNear(
      image,
      w - margin,
      0,
      margin,
      OrientationMarkers.topRight,
    );
    final bl = _findMarkerNear(
      image,
      0,
      h - margin,
      margin,
      OrientationMarkers.bottomLeft,
    );
    final br = _findMarkerNear(
      image,
      w - margin,
      h - margin,
      margin,
      OrientationMarkers.bottomRight,
    );

    if (tl == null || tr == null || bl == null || br == null) {
      // Fallback: use image bounds as corners
      return [
        _Point(0, 0),
        _Point((w - 1).toDouble(), 0),
        _Point(0, (h - 1).toDouble()),
        _Point((w - 1).toDouble(), (h - 1).toDouble()),
      ];
    }

    return [tl, tr, bl, br];
  }

  _Point? _findMarkerNear(
    img.Image image,
    int cx,
    int cy,
    int radius,
    ColorCell target,
  ) {
    var bestDist = double.infinity;
    _Point? best;

    for (var y = (cy - radius).clamp(0, image.height - 1);
        y <= (cy + radius).clamp(0, image.height - 1);
        y++) {
      for (var x = (cx - radius).clamp(0, image.width - 1);
          x <= (cx + radius).clamp(0, image.width - 1);
          x++) {
        final p = image.getPixel(x, y);
        final dr = p.r.toInt() - target.r;
        final dg = p.g.toInt() - target.g;
        final db = p.b.toInt() - target.b;
        final dist = math.sqrt(
          (dr * dr + dg * dg + db * db).toDouble(),
        );
        if (dist < bestDist && dist < 80) {
          bestDist = dist;
          best = _Point(x.toDouble(), y.toDouble());
        }
      }
    }
    return best;
  }

  List<ColorCell> _sampleGrid(
    img.Image image,
    List<_Point> corners,
    int gridSize,
  ) {
    final totalCells = gridSize + marginCells * 2;
    final cells = <ColorCell>[];

    final topLeft = corners[0];
    final topRight = corners[1];
    final bottomLeft = corners[2];

    for (var row = 0; row < gridSize; row++) {
      for (var col = 0; col < gridSize; col++) {
        final u = (col + marginCells + 0.5) / totalCells;
        final v = (row + marginCells + 0.5) / totalCells;

        final top = _lerp(topLeft, topRight, u);
        final bottom = _lerp(bottomLeft, corners[3], u);
        final point = _lerp(top, bottom, v);

        final px = point.x.round().clamp(0, image.width - 1);
        final py = point.y.round().clamp(0, image.height - 1);
        final pixel = image.getPixel(px, py);

        cells.add(
          ColorPalette.rgbToCell(
            pixel.r.toInt(),
            pixel.g.toInt(),
            pixel.b.toInt(),
          ),
        );
      }
    }

    return cells;
  }

  _Point _lerp(_Point a, _Point b, double t) {
    return _Point(
      a.x + (b.x - a.x) * t,
      a.y + (b.y - a.y) * t,
    );
  }

  double _estimateAccuracy(List<ColorCell> cells) {
    if (cells.isEmpty) return 0;
    var valid = 0;
    for (final cell in cells) {
      if (cell.value != null) valid++;
    }
    return valid / cells.length;
  }
}

class _Point {
  const _Point(this.x, this.y);
  final double x;
  final double y;
}
