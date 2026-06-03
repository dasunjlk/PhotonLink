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
    );
  }
}
