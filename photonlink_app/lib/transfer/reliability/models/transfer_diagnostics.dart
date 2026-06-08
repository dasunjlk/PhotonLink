/// Snapshot of transfer diagnostics for UI and history.
class TransferDiagnostics {
  const TransferDiagnostics({
    this.packetsSent = 0,
    this.packetsReceived = 0,
    this.missingPackets = 0,
    this.retries = 0,
    this.duplicates = 0,
    this.accepted = 0,
    this.progress = 0,
    this.durationMs = 0,
    this.throughputBytesPerSec = 0,
    this.estimatedRemainingMs,
    this.failureReason,
    this.startedAt,
    this.completedAt,
    this.ackCount = 0,
    this.nakCount = 0,
    this.compressionSavingsBytes = 0,
    this.compressionRatio = 1,
    this.encryptionUsed = false,
    this.transferSpeedBytesPerSec = 0,
  });

  final int packetsSent;
  final int packetsReceived;
  final int missingPackets;
  final int retries;
  final int duplicates;
  final int accepted;
  final double progress;
  final int durationMs;
  final double throughputBytesPerSec;
  final int? estimatedRemainingMs;
  final String? failureReason;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int ackCount;
  final int nakCount;
  final int compressionSavingsBytes;
  final double compressionRatio;
  final bool encryptionUsed;
  final double transferSpeedBytesPerSec;

  TransferDiagnostics copyWith({
    int? packetsSent,
    int? packetsReceived,
    int? missingPackets,
    int? retries,
    int? duplicates,
    int? accepted,
    double? progress,
    int? durationMs,
    double? throughputBytesPerSec,
    int? estimatedRemainingMs,
    String? failureReason,
    DateTime? startedAt,
    DateTime? completedAt,
    int? ackCount,
    int? nakCount,
    int? compressionSavingsBytes,
    double? compressionRatio,
    bool? encryptionUsed,
    double? transferSpeedBytesPerSec,
  }) {
    return TransferDiagnostics(
      packetsSent: packetsSent ?? this.packetsSent,
      packetsReceived: packetsReceived ?? this.packetsReceived,
      missingPackets: missingPackets ?? this.missingPackets,
      retries: retries ?? this.retries,
      duplicates: duplicates ?? this.duplicates,
      accepted: accepted ?? this.accepted,
      progress: progress ?? this.progress,
      durationMs: durationMs ?? this.durationMs,
      throughputBytesPerSec:
          throughputBytesPerSec ?? this.throughputBytesPerSec,
      estimatedRemainingMs: estimatedRemainingMs ?? this.estimatedRemainingMs,
      failureReason: failureReason ?? this.failureReason,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      ackCount: ackCount ?? this.ackCount,
      nakCount: nakCount ?? this.nakCount,
      compressionSavingsBytes:
          compressionSavingsBytes ?? this.compressionSavingsBytes,
      compressionRatio: compressionRatio ?? this.compressionRatio,
      encryptionUsed: encryptionUsed ?? this.encryptionUsed,
      transferSpeedBytesPerSec:
          transferSpeedBytesPerSec ?? this.transferSpeedBytesPerSec,
    );
  }

  Map<String, dynamic> toJson() => {
        'packetsSent': packetsSent,
        'packetsReceived': packetsReceived,
        'missingPackets': missingPackets,
        'retries': retries,
        'duplicates': duplicates,
        'accepted': accepted,
        'progress': progress,
        'durationMs': durationMs,
        'throughputBytesPerSec': throughputBytesPerSec,
        if (estimatedRemainingMs != null)
          'estimatedRemainingMs': estimatedRemainingMs,
        if (failureReason != null) 'failureReason': failureReason,
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'ackCount': ackCount,
        'nakCount': nakCount,
        'compressionSavingsBytes': compressionSavingsBytes,
        'compressionRatio': compressionRatio,
        'encryptionUsed': encryptionUsed,
        'transferSpeedBytesPerSec': transferSpeedBytesPerSec,
      };

  factory TransferDiagnostics.fromJson(Map<String, dynamic> json) {
    return TransferDiagnostics(
      packetsSent: json['packetsSent'] as int? ?? 0,
      packetsReceived: json['packetsReceived'] as int? ?? 0,
      missingPackets: json['missingPackets'] as int? ?? 0,
      retries: json['retries'] as int? ?? 0,
      duplicates: json['duplicates'] as int? ?? 0,
      accepted: json['accepted'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      durationMs: json['durationMs'] as int? ?? 0,
      throughputBytesPerSec:
          (json['throughputBytesPerSec'] as num?)?.toDouble() ?? 0,
      estimatedRemainingMs: json['estimatedRemainingMs'] as int?,
      failureReason: json['failureReason'] as String?,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      ackCount: json['ackCount'] as int? ?? 0,
      nakCount: json['nakCount'] as int? ?? 0,
      compressionSavingsBytes: json['compressionSavingsBytes'] as int? ?? 0,
      compressionRatio: (json['compressionRatio'] as num?)?.toDouble() ?? 1,
      encryptionUsed: json['encryptionUsed'] as bool? ?? false,
      transferSpeedBytesPerSec:
          (json['transferSpeedBytesPerSec'] as num?)?.toDouble() ?? 0,
    );
  }
}
