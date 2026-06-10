import 'models/environment_profile.dart';

/// Rolling-window environmental signal aggregator.
class EnvironmentAnalyzer {
  EnvironmentAnalyzer({this.windowSize = 30});

  final int windowSize;

  final List<double> _brightnessSamples = [];
  final List<bool> _detectionSamples = [];
  final List<bool> _decodeSuccessSamples = [];
  int _framesAttempted = 0;
  int _framesLost = 0;

  EnvironmentProfile get current => _buildProfile();

  void recordBrightness(double normalizedBrightness) {
    _brightnessSamples.add(normalizedBrightness.clamp(0.0, 1.0));
    if (_brightnessSamples.length > windowSize) {
      _brightnessSamples.removeAt(0);
    }
  }

  void recordDetectionAttempt({required bool success}) {
    _framesAttempted++;
    _detectionSamples.add(success);
    if (!success) _framesLost++;
    if (_detectionSamples.length > windowSize) {
      _detectionSamples.removeAt(0);
    }
  }

  void recordDecodeAttempt({required bool success}) {
    _decodeSuccessSamples.add(success);
    if (_decodeSuccessSamples.length > windowSize) {
      _decodeSuccessSamples.removeAt(0);
    }
  }

  void reset() {
    _brightnessSamples.clear();
    _detectionSamples.clear();
    _decodeSuccessSamples.clear();
    _framesAttempted = 0;
    _framesLost = 0;
  }

  EnvironmentProfile _buildProfile() {
    final avgBrightness = _brightnessSamples.isEmpty
        ? 0.5
        : _brightnessSamples.reduce((a, b) => a + b) /
            _brightnessSamples.length;

    var variance = 0.0;
    if (_brightnessSamples.length > 1) {
      final mean = avgBrightness;
      variance = _brightnessSamples
              .map((b) => (b - mean) * (b - mean))
              .reduce((a, b) => a + b) /
          _brightnessSamples.length;
    }

    final detectionRate = _detectionSamples.isEmpty
        ? 1.0
        : _detectionSamples.where((s) => s).length /
            _detectionSamples.length;

    final decodeRate = _decodeSuccessSamples.isEmpty
        ? 1.0
        : _decodeSuccessSamples.where((s) => s).length /
            _decodeSuccessSamples.length;

    final lossRate = _framesAttempted == 0
        ? 0.0
        : _framesLost / _framesAttempted;

    return EnvironmentProfile(
      avgBrightness: avgBrightness,
      brightnessVariance: variance,
      detectionSuccessRate: detectionRate,
      frameLossRate: lossRate,
      decodeErrorRate: 1.0 - decodeRate,
      samples: _brightnessSamples.length,
    );
  }
}
