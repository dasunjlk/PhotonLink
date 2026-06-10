import '../../../protocols/interfaces/transfer_packet.dart';

/// Per-block recovery summary.
class FecBlockRecoverySummary {
  const FecBlockRecoverySummary({
    required this.blockIndex,
    required this.dataCount,
    required this.parityCount,
    required this.missingBefore,
    required this.recoveredCount,
    required this.success,
  });

  final int blockIndex;
  final int dataCount;
  final int parityCount;
  final int missingBefore;
  final int recoveredCount;
  final bool success;
}

/// Result of an FEC recovery attempt.
class FecRecoveryResult {
  const FecRecoveryResult({
    this.recovered = const {},
    this.unrecoverableBlocks = const [],
    this.blockSummaries = const [],
    this.success = false,
  });

  final Map<int, DataPacket> recovered;
  final List<int> unrecoverableBlocks;
  final List<FecBlockRecoverySummary> blockSummaries;
  final bool success;

  int get recoveredCount => recovered.length;
}
