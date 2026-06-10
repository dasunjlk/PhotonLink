/// Quality score (0–100) with per-factor breakdown.
class QualityScore {
  const QualityScore({
    required this.score,
    this.frameLossFactor = 100,
    this.decodeErrorFactor = 100,
    this.retryFactor = 100,
    this.detectionStabilityFactor = 100,
    this.brightnessFactor = 100,
    this.recoveryFactor = 100,
  });

  final double score;
  final double frameLossFactor;
  final double decodeErrorFactor;
  final double retryFactor;
  final double detectionStabilityFactor;
  final double brightnessFactor;
  final double recoveryFactor;

  static const QualityScore unknown = QualityScore(score: 50);

  Map<String, dynamic> toJson() => {
        'score': score,
        'frameLossFactor': frameLossFactor,
        'decodeErrorFactor': decodeErrorFactor,
        'retryFactor': retryFactor,
        'detectionStabilityFactor': detectionStabilityFactor,
        'brightnessFactor': brightnessFactor,
        'recoveryFactor': recoveryFactor,
      };

  factory QualityScore.fromJson(Map<String, dynamic> json) {
    return QualityScore(
      score: (json['score'] as num?)?.toDouble() ?? 50,
      frameLossFactor: (json['frameLossFactor'] as num?)?.toDouble() ?? 100,
      decodeErrorFactor:
          (json['decodeErrorFactor'] as num?)?.toDouble() ?? 100,
      retryFactor: (json['retryFactor'] as num?)?.toDouble() ?? 100,
      detectionStabilityFactor:
          (json['detectionStabilityFactor'] as num?)?.toDouble() ?? 100,
      brightnessFactor: (json['brightnessFactor'] as num?)?.toDouble() ?? 100,
      recoveryFactor: (json['recoveryFactor'] as num?)?.toDouble() ?? 100,
    );
  }
}
