/// Adaptive frame pacing with jitter smoothing and throughput stabilization.
class StreamTimingController {
  StreamTimingController({
    double framesPerSecond = 8.0,
    this.minIntervalMs = 50,
    this.maxIntervalMs = 10000,
    this.jitterAlpha = 0.3,
    this.driftAlpha = 0.15,
  }) : _targetIntervalMs = _fpsToInterval(framesPerSecond);

  final int minIntervalMs;
  final int maxIntervalMs;
  final double jitterAlpha;
  final double driftAlpha;

  int _targetIntervalMs;
  int _smoothedIntervalMs = 0;
  int _lastEmitMs = 0;
  int _framesEmitted = 0;
  int _framesDecoded = 0;
  double _measuredDecodeFps = 0;
  double _jitterMs = 0;

  double get framesPerSecond => 1000.0 / _targetIntervalMs;
  int get targetIntervalMs => _targetIntervalMs;
  int get smoothedIntervalMs =>
      _smoothedIntervalMs > 0 ? _smoothedIntervalMs : _targetIntervalMs;
  double get jitterMs => _jitterMs;
  double get measuredDecodeFps => _measuredDecodeFps;
  int get framesEmitted => _framesEmitted;
  int get framesDecoded => _framesDecoded;

  void setTargetFps(double fps) {
    _targetIntervalMs = _fpsToInterval(fps);
  }

  /// Call before emitting a frame; returns recommended delay until next emit.
  int onEmit(int nowMs) {
    if (_lastEmitMs > 0) {
      final delta = nowMs - _lastEmitMs;
      _jitterMs = _jitterMs == 0
          ? (delta - _targetIntervalMs).abs().toDouble()
          : jitterAlpha * (delta - _targetIntervalMs).abs() +
              (1 - jitterAlpha) * _jitterMs;
      _smoothedIntervalMs = _smoothedIntervalMs == 0
          ? delta
          : (jitterAlpha * delta + (1 - jitterAlpha) * _smoothedIntervalMs)
              .round();
    }
    _lastEmitMs = nowMs;
    _framesEmitted++;
    return smoothedIntervalMs;
  }

  /// Call when receiver successfully decodes a frame.
  void onDecode(int nowMs, {int? sinceLastDecodeMs}) {
    _framesDecoded++;
    if (sinceLastDecodeMs != null && sinceLastDecodeMs > 0) {
      final instantFps = 1000.0 / sinceLastDecodeMs;
      _measuredDecodeFps = _measuredDecodeFps == 0
          ? instantFps
          : driftAlpha * instantFps + (1 - driftAlpha) * _measuredDecodeFps;
      _stabilizeTowardDecodeRate();
    }
  }

  void onDroppedFrame() {
    // Slightly slow down to reduce loss.
    _targetIntervalMs = (_targetIntervalMs * 1.05).round().clamp(
          minIntervalMs,
          maxIntervalMs,
        );
  }

  void reset() {
    _lastEmitMs = 0;
    _framesEmitted = 0;
    _framesDecoded = 0;
    _measuredDecodeFps = 0;
    _jitterMs = 0;
    _smoothedIntervalMs = 0;
  }

  void _stabilizeTowardDecodeRate() {
    if (_measuredDecodeFps <= 0) return;
    final decodeInterval = _fpsToInterval(_measuredDecodeFps);
    final adjusted = (0.7 * _targetIntervalMs + 0.3 * decodeInterval).round();
    _targetIntervalMs = adjusted.clamp(minIntervalMs, maxIntervalMs);
  }

  static int _fpsToInterval(double fps) {
    if (fps <= 0) return 1000;
    return (1000 / fps).round().clamp(50, 10000);
  }
}
