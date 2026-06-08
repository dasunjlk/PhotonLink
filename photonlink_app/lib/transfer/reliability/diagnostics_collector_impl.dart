import '../../protocols/interfaces/reliability/diagnostics_collector.dart';
import 'models/transfer_diagnostics.dart';

/// Collects transfer metrics for UI and history.
class DiagnosticsCollectorImpl implements DiagnosticsCollector {
  TransferDiagnostics _data = const TransferDiagnostics();
  DateTime? _startedAt;
  int _bytesTransferred = 0;

  @override
  TransferDiagnostics get snapshot => _data;

  @override
  void reset() {
    _data = const TransferDiagnostics();
    _startedAt = null;
    _bytesTransferred = 0;
  }

  @override
  void startSession() {
    _startedAt = DateTime.now();
    _data = TransferDiagnostics(startedAt: _startedAt);
  }

  @override
  void recordSent({int count = 1}) {
    _data = _data.copyWith(packetsSent: _data.packetsSent + count);
    _refreshTiming();
  }

  @override
  void recordReceived({int count = 1}) {
    _data = _data.copyWith(
      packetsReceived: _data.packetsReceived + count,
      accepted: _data.accepted + count,
    );
    _refreshTiming();
  }

  @override
  void recordDuplicate() {
    _data = _data.copyWith(duplicates: _data.duplicates + 1);
  }

  @override
  void recordRetry() {
    _data = _data.copyWith(retries: _data.retries + 1);
  }

  @override
  void recordMissing(int count) {
    _data = _data.copyWith(missingPackets: count);
  }

  @override
  void recordAck() {
    _data = _data.copyWith(ackCount: _data.ackCount + 1);
  }

  @override
  void recordNak() {
    _data = _data.copyWith(nakCount: _data.nakCount + 1);
  }

  @override
  void recordBytes(int bytes) {
    _bytesTransferred += bytes;
    _refreshTiming();
  }

  @override
  void setCompressionStats({required int savingsBytes, required double ratio}) {
    _data = _data.copyWith(
      compressionSavingsBytes: savingsBytes,
      compressionRatio: ratio,
    );
  }

  @override
  void setEncryptionUsed(bool used) {
    _data = _data.copyWith(encryptionUsed: used);
  }

  @override
  void updateProgress(double fraction) {
    _data = _data.copyWith(progress: fraction.clamp(0, 1));
    _updateEta(fraction);
  }

  @override
  void markCompleted() {
    _data = _data.copyWith(
      completedAt: DateTime.now(),
      progress: 1,
    );
    _refreshTiming();
  }

  @override
  void markFailed(String? reason) {
    _data = _data.copyWith(
      failureReason: reason,
      completedAt: DateTime.now(),
    );
    _refreshTiming();
  }

  void _refreshTiming() {
    if (_startedAt == null) return;
    final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
    final throughput = elapsed > 0
        ? _bytesTransferred / (elapsed / 1000)
        : 0.0;
    _data = _data.copyWith(
      durationMs: elapsed,
      throughputBytesPerSec: throughput,
      transferSpeedBytesPerSec: throughput,
    );
  }

  void _updateEta(double fraction) {
    if (_startedAt == null || fraction <= 0 || fraction >= 1) return;
    final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
    final remaining = (elapsed / fraction * (1 - fraction)).round();
    _data = _data.copyWith(estimatedRemainingMs: remaining);
  }
}
