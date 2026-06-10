import 'models/throughput_snapshot.dart';

/// Tracks throughput, packet rate, and transform overhead.
class ThroughputMonitor {
  DateTime? _startedAt;
  int _totalBytes = 0;
  int _packetCount = 0;
  double _peakBytesPerSec = 0;
  double _compressionRatio = 1;
  int _encryptionOverheadBytes = 0;
  DateTime? _lastSampleAt;
  int _lastSampleBytes = 0;
  double _currentBytesPerSec = 0;

  void start() {
    _startedAt = DateTime.now();
    _lastSampleAt = _startedAt;
    _totalBytes = 0;
    _packetCount = 0;
    _peakBytesPerSec = 0;
    _currentBytesPerSec = 0;
    _lastSampleBytes = 0;
  }

  void reset() {
    _startedAt = null;
    _totalBytes = 0;
    _packetCount = 0;
    _peakBytesPerSec = 0;
    _compressionRatio = 1;
    _encryptionOverheadBytes = 0;
    _currentBytesPerSec = 0;
    _lastSampleAt = null;
    _lastSampleBytes = 0;
  }

  void recordBytes(int bytes, {bool isPacket = true}) {
    if (_startedAt == null) start();
    _totalBytes += bytes;
    if (isPacket) _packetCount++;
    _refresh();
  }

  void setCompressionRatio(double ratio) {
    _compressionRatio = ratio;
  }

  void addEncryptionOverhead(int bytes) {
    _encryptionOverheadBytes += bytes;
  }

  void _refresh() {
    final started = _startedAt;
    if (started == null) return;
    final now = DateTime.now();
    final elapsedMs = now.difference(started).inMilliseconds;
    if (elapsedMs <= 0) return;

    final avg = _totalBytes / (elapsedMs / 1000);
    if (avg > _peakBytesPerSec) _peakBytesPerSec = avg;

    final last = _lastSampleAt;
    if (last != null) {
      final deltaMs = now.difference(last).inMilliseconds;
      if (deltaMs > 0) {
        final deltaBytes = _totalBytes - _lastSampleBytes;
        _currentBytesPerSec = deltaBytes / (deltaMs / 1000);
        _lastSampleAt = now;
        _lastSampleBytes = _totalBytes;
      }
    }
  }

  ThroughputSnapshot snapshot() {
    final started = _startedAt;
    final elapsedMs =
        started != null ? DateTime.now().difference(started).inMilliseconds : 0;
    final sec = elapsedMs > 0 ? elapsedMs / 1000 : 0.0;
    return ThroughputSnapshot(
      currentBytesPerSec: _currentBytesPerSec,
      averageBytesPerSec: sec > 0 ? _totalBytes / sec : 0,
      peakBytesPerSec: _peakBytesPerSec,
      packetsPerSec: sec > 0 ? _packetCount / sec : 0,
      durationMs: elapsedMs,
      compressionRatio: _compressionRatio,
      encryptionOverheadBytes: _encryptionOverheadBytes,
      totalBytes: _totalBytes,
    );
  }
}
