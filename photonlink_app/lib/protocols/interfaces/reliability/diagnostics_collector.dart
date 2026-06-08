import '../../../transfer/reliability/models/transfer_diagnostics.dart';

/// Collects transfer diagnostics (transport-agnostic).
abstract interface class DiagnosticsCollector {
  TransferDiagnostics get snapshot;

  void reset();

  void startSession();

  void recordSent({int count = 1});

  void recordReceived({int count = 1});

  void recordDuplicate();

  void recordRetry();

  void recordMissing(int count);

  void recordAck();

  void recordNak();

  void recordBytes(int bytes);

  void setCompressionStats({required int savingsBytes, required double ratio});

  void setEncryptionUsed(bool used);

  void updateProgress(double fraction);

  void markCompleted();

  void markFailed(String? reason);
}
