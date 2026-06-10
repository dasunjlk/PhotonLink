/// Aggregated FEC diagnostics for a transfer session.
class FecStatistics {
  const FecStatistics({
    this.parityGenerated = 0,
    this.packetsLost = 0,
    this.packetsRecovered = 0,
    this.recoveryAttempts = 0,
    this.recoverySuccessCount = 0,
    this.parityConsumed = 0,
    this.recoveryTimeMs = 0,
  });

  final int parityGenerated;
  final int packetsLost;
  final int packetsRecovered;
  final int recoveryAttempts;
  final int recoverySuccessCount;
  final int parityConsumed;
  final int recoveryTimeMs;

  double get recoverySuccessRate =>
      recoveryAttempts == 0 ? 0.0 : recoverySuccessCount / recoveryAttempts;

  double get parityEfficiency =>
      parityConsumed == 0 ? 0.0 : packetsRecovered / parityConsumed;

  double get fecOverhead =>
      packetsRecovered + packetsLost == 0
          ? 0.0
          : parityGenerated / (packetsRecovered + packetsLost + 1);

  FecStatistics copyWith({
    int? parityGenerated,
    int? packetsLost,
    int? packetsRecovered,
    int? recoveryAttempts,
    int? recoverySuccessCount,
    int? parityConsumed,
    int? recoveryTimeMs,
  }) {
    return FecStatistics(
      parityGenerated: parityGenerated ?? this.parityGenerated,
      packetsLost: packetsLost ?? this.packetsLost,
      packetsRecovered: packetsRecovered ?? this.packetsRecovered,
      recoveryAttempts: recoveryAttempts ?? this.recoveryAttempts,
      recoverySuccessCount: recoverySuccessCount ?? this.recoverySuccessCount,
      parityConsumed: parityConsumed ?? this.parityConsumed,
      recoveryTimeMs: recoveryTimeMs ?? this.recoveryTimeMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'parityGenerated': parityGenerated,
        'packetsLost': packetsLost,
        'packetsRecovered': packetsRecovered,
        'recoveryAttempts': recoveryAttempts,
        'recoverySuccessCount': recoverySuccessCount,
        'parityConsumed': parityConsumed,
        'recoveryTimeMs': recoveryTimeMs,
        'recoverySuccessRate': recoverySuccessRate,
        'parityEfficiency': parityEfficiency,
        'fecOverhead': fecOverhead,
      };

  factory FecStatistics.fromJson(Map<String, dynamic> json) {
    return FecStatistics(
      parityGenerated: json['parityGenerated'] as int? ?? 0,
      packetsLost: json['packetsLost'] as int? ?? 0,
      packetsRecovered: json['packetsRecovered'] as int? ?? 0,
      recoveryAttempts: json['recoveryAttempts'] as int? ?? 0,
      recoverySuccessCount: json['recoverySuccessCount'] as int? ?? 0,
      parityConsumed: json['parityConsumed'] as int? ?? 0,
      recoveryTimeMs: json['recoveryTimeMs'] as int? ?? 0,
    );
  }
}
