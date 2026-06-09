import 'dart:typed_data';

import 'package:camera/camera.dart';

/// Cheap Y-plane brightness sampling from camera frames.
class BrightnessSampler {
  const BrightnessSampler();

  /// Returns normalized brightness 0–1 and variance 0–1.
  ({double avg, double variance}) sampleFromYuv(CameraImage image) {
    final plane = image.planes.first;
    final bytes = plane.bytes;
    if (bytes.isEmpty) return (avg: 0.5, variance: 0);

    final step = (bytes.length / 256).round().clamp(1, bytes.length);
    var sum = 0.0;
    var count = 0;
    final samples = <double>[];

    for (var i = 0; i < bytes.length; i += step) {
      final v = bytes[i] / 255.0;
      sum += v;
      samples.add(v);
      count++;
    }

    if (count == 0) return (avg: 0.5, variance: 0);
    final avg = sum / count;
    var varSum = 0.0;
    for (final s in samples) {
      varSum += (s - avg) * (s - avg);
    }
    final variance = samples.length > 1 ? varSum / samples.length : 0.0;
    return (avg: avg, variance: variance);
  }

  ({double avg, double variance}) sampleFromRgb(
    Uint8List rgbBytes, {
    int sampleCount = 256,
  }) {
    if (rgbBytes.isEmpty) return (avg: 0.5, variance: 0);
    final step = (rgbBytes.length / (sampleCount * 3)).round().clamp(3, rgbBytes.length);
    var sum = 0.0;
    var count = 0;
    final samples = <double>[];

    for (var i = 0; i < rgbBytes.length - 2; i += step) {
      final r = rgbBytes[i];
      final g = rgbBytes[i + 1];
      final b = rgbBytes[i + 2];
      final lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
      sum += lum;
      samples.add(lum);
      count++;
    }

    if (count == 0) return (avg: 0.5, variance: 0);
    final avg = sum / count;
    var varSum = 0.0;
    for (final s in samples) {
      varSum += (s - avg) * (s - avg);
    }
    return (avg: avg, variance: varSum / samples.length);
  }
}
