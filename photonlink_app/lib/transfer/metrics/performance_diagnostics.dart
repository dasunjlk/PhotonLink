import '../reliability/models/transfer_diagnostics.dart';
import 'models/throughput_snapshot.dart';

/// Exportable performance + reliability report (Phase 4).
class PerformanceDiagnostics {
  const PerformanceDiagnostics({
    required this.transfer,
    required this.throughput,
    this.compressionUsed = false,
    this.encryptionUsed = false,
    this.compressionRatio = 1,
    this.protocolVersion = 2,
  });

  final TransferDiagnostics transfer;
  final ThroughputSnapshot throughput;
  final bool compressionUsed;
  final bool encryptionUsed;
  final double compressionRatio;
  final int protocolVersion;

  Map<String, dynamic> toJson() => {
        'protocolVersion': protocolVersion,
        'compressionUsed': compressionUsed,
        'encryptionUsed': encryptionUsed,
        'compressionRatio': compressionRatio,
        'transfer': transfer.toJson(),
        'throughput': throughput.toJson(),
      };

  factory PerformanceDiagnostics.fromParts({
    required TransferDiagnostics transfer,
    required ThroughputSnapshot throughput,
    bool compressionUsed = false,
    bool encryptionUsed = false,
    double compressionRatio = 1,
    int protocolVersion = 2,
  }) {
    return PerformanceDiagnostics(
      transfer: transfer,
      throughput: throughput,
      compressionUsed: compressionUsed,
      encryptionUsed: encryptionUsed,
      compressionRatio: compressionRatio,
      protocolVersion: protocolVersion,
    );
  }
}
