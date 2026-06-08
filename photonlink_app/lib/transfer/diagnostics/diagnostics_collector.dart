import 'dart:convert';

import '../../protocols/interfaces/reliability/transfer_diagnostics.dart';
import '../../services/storage/preferences_service.dart';

/// Collects and persists transfer diagnostics metrics.
class DiagnosticsCollector {
  DiagnosticsCollector(this._prefs);

  final PreferencesService _prefs;
  static const _keyPrefix = 'transfer_diagnostics_';

  TransferDiagnostics _current = const TransferDiagnostics();
  final List<double> _decodeTimes = [];
  DateTime? _receiveStart;
  int _bytesReceived = 0;

  TransferDiagnostics get current => _current;

  void reset() {
    _current = const TransferDiagnostics();
    _decodeTimes.clear();
    _receiveStart = null;
    _bytesReceived = 0;
  }

  void recordFrameGenerated() {
    _current = _current.copyWith(
      framesGenerated: _current.framesGenerated + 1,
    );
  }

  void recordFrameReceived({int payloadBytes = 0}) {
    _receiveStart ??= DateTime.now();
    _bytesReceived += payloadBytes;
    _current = _current.copyWith(
      framesReceived: _current.framesReceived + 1,
    );
    _updateThroughput();
  }

  void recordFrameCorrupted() {
    _current = _current.copyWith(
      framesCorrupted: _current.framesCorrupted + 1,
    );
  }

  void recordFrameLost(int count) {
    _current = _current.copyWith(
      framesLost: _current.framesLost + count,
    );
  }

  void recordFrameRetried() {
    _current = _current.copyWith(
      framesRetried: _current.framesRetried + 1,
    );
  }

  void recordDuplicate() {
    _current = _current.copyWith(
      duplicatesIgnored: _current.duplicatesIgnored + 1,
    );
  }

  void recordDecodeTime(Duration duration) {
    _decodeTimes.add(duration.inMicroseconds / 1000.0);
    if (_decodeTimes.length > 100) _decodeTimes.removeAt(0);
    final avg = _decodeTimes.reduce((a, b) => a + b) / _decodeTimes.length;
    _current = _current.copyWith(avgDecodeTimeMs: avg);
  }

  void recordDetectionAccuracy(double accuracy) {
    _current = _current.copyWith(detectionAccuracy: accuracy);
  }

  void updateMissingCount(int count) {
    _current = _current.copyWith(missingPacketCount: count);
  }

  void _updateThroughput() {
    if (_receiveStart == null) return;
    final elapsed = DateTime.now().difference(_receiveStart!).inMilliseconds;
    if (elapsed <= 0) return;
    final bps = _bytesReceived / (elapsed / 1000.0);
    _current = _current.copyWith(throughputBytesPerSecond: bps);
  }

  Future<void> persist(String sessionId) async {
    await _prefs.setString(
      '$_keyPrefix$sessionId',
      jsonEncode(_current.toJson()),
    );
  }

  Future<TransferDiagnostics?> load(String sessionId) async {
    final raw = _prefs.getString('$_keyPrefix$sessionId');
    if (raw == null) return null;
    return TransferDiagnostics.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}
