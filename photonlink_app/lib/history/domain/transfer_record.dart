import '../../protocols/transfer_method.dart';

/// Direction of a transfer relative to this device.
enum TransferDirection {
  sent('Sent'),
  received('Received');

  const TransferDirection(this.label);
  final String label;
}

/// Status of a completed or attempted transfer.
enum TransferStatus {
  success('Success'),
  failed('Failed'),
  cancelled('Cancelled'),
  inProgress('In Progress');

  const TransferStatus(this.label);
  final String label;
}

/// A single entry in the transfer history log.
class TransferRecord {
  const TransferRecord({
    required this.id,
    required this.fileName,
    required this.method,
    required this.sizeBytes,
    required this.status,
    required this.timestamp,
    required this.direction,
    this.sessionId,
    this.durationMs = 0,
    this.retryCount = 0,
    this.failureReason,
    this.compressionUsed = false,
    this.encryptionUsed = false,
    this.compressionRatio,
    this.transferSpeedBytesPerSec,
    this.avgQualityScore,
    this.avgThroughput,
    this.profileUsed,
    this.adaptiveEventCount = 0,
    this.environmentSummary,
    this.protocolVersion = 5,
    this.fecProfile,
    this.packetsRecovered = 0,
    this.recoveryRate,
    this.parityOverhead,
  });

  final String id;
  final String fileName;
  final TransferMethod method;
  final int sizeBytes;
  final TransferStatus status;
  final DateTime timestamp;
  final TransferDirection direction;
  final String? sessionId;
  final int durationMs;
  final int retryCount;
  final String? failureReason;
  final bool compressionUsed;
  final bool encryptionUsed;
  final double? compressionRatio;
  final double? transferSpeedBytesPerSec;
  final double? avgQualityScore;
  final double? avgThroughput;
  final String? profileUsed;
  final int adaptiveEventCount;
  final String? environmentSummary;
  final int protocolVersion;
  final String? fecProfile;
  final int packetsRecovered;
  final double? recoveryRate;
  final double? parityOverhead;
}
