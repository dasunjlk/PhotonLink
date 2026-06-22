import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'optical_pattern.dart';
import 'optical_stream_frame.dart';

/// Result of detecting an optical stream grid in a camera frame.
class OpticalDetectionResult {
  const OpticalDetectionResult({
    required this.cells,
    required this.gridSize,
    required this.detected,
    required this.accuracy,
    this.syncLocked = false,
    this.orientation = 0,
  });

  final List<BrightnessCell> cells;
  final int gridSize;
  final bool detected;
  final double accuracy;
  final bool syncLocked;
  final int orientation;
}

/// Detects optical stream grids in captured camera frames.
class OpticalDetector {
  const OpticalDetector({
    this.defaultGridSize = 24,
    this.marginCells = OpticalPattern.marginCells,
    this.syncThreshold = 0.6,
  });

  final int defaultGridSize;
  final int marginCells;
  final double syncThreshold;

  /// Detects and extracts data cells from [imageBytes] (PNG/JPEG/raw RGB).
  OpticalDetectionResult detect(Uint8List imageBytes, {int? gridSize}) {
    final grid = gridSize ?? defaultGridSize;
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      return OpticalDetectionResult(
        cells: [],
        gridSize: grid,
        detected: false,
        accuracy: 0,
      );
    }

    final corners = _findCorners(image);
    if (corners == null) {
      return OpticalDetectionResult(
        cells: [],
        gridSize: grid,
        detected: false,
        accuracy: 0,
      );
    }

    final cells = _sampleGrid(image, corners, grid);
    final accuracy = _estimateAccuracy(cells);
    final syncLocked = accuracy >= syncThreshold;

    return OpticalDetectionResult(
      cells: cells,
      gridSize: grid,
      detected: cells.isNotEmpty,
      accuracy: accuracy,
      syncLocked: syncLocked,
    );
  }

  /// Detects from a raw RGB buffer (width x height).
  OpticalDetectionResult detectFromRgb({
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
    final w = image.width;
    final h = image.height;
    final margin = (w * 0.05).round();

    final tl = _findMarkerNear(
      image,
      0,
      0,
      margin,
      OpticalPattern.topLeftMarker,
    );
    final tr = _findMarkerNear(
      image,
      w - margin,
      0,
      margin,
      OpticalPattern.topRightMarker,
    );
    final bl = _findMarkerNear(
      image,
      0,
      h - margin,
      margin,
      OpticalPattern.bottomLeftMarker,
    );
    final br = _findMarkerNear(
      image,
      w - margin,
      h - margin,
      margin,
      OpticalPattern.bottomRightMarker,
    );

    if (tl == null || tr == null || bl == null || br == null) {
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
    BrightnessCell target,
  ) {
    var bestDist = double.infinity;
    _Point? best;
    final targetGray = (target.brightness * 255).round();

    for (var y = (cy - radius).clamp(0, image.height - 1);
        y <= (cy + radius).clamp(0, image.height - 1);
        y++) {
      for (var x = (cx - radius).clamp(0, image.width - 1);
          x <= (cx + radius).clamp(0, image.width - 1);
          x++) {
        final p = image.getPixel(x, y);
        final gray = p.r.toInt();
        final dist = (gray - targetGray).abs().toDouble();
        if (dist < bestDist && dist < 80) {
          bestDist = dist;
          best = _Point(x.toDouble(), y.toDouble());
        }
      }
    }
    return best;
  }

  List<BrightnessCell> _sampleGrid(
    img.Image image,
    List<_Point> corners,
    int gridSize,
  ) {
    final totalCells = gridSize + marginCells * 2;
    final cells = <BrightnessCell>[];

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
        final gray = pixel.r.toInt() / 255.0;
        final bit = gray >= 0.5 ? 1 : 0;

        cells.add(BrightnessCell(brightness: gray, bit: bit));
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

  double _estimateAccuracy(List<BrightnessCell> cells) {
    if (cells.isEmpty) return 0;
    var valid = 0;
    for (final cell in cells) {
      if (cell.bit != null) valid++;
    }
    return valid / cells.length;
  }
}

class _Point {
  const _Point(this.x, this.y);
  final double x;
  final double y;
}
