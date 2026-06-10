/// Rolling environmental conditions during optical transfer.
class EnvironmentProfile {
  const EnvironmentProfile({
    this.avgBrightness = 0.5,
    this.brightnessVariance = 0,
    this.detectionSuccessRate = 1.0,
    this.frameLossRate = 0,
    this.decodeErrorRate = 0,
    this.samples = 0,
  });

  final double avgBrightness;
  final double brightnessVariance;
  final double detectionSuccessRate;
  final double frameLossRate;
  final double decodeErrorRate;
  final int samples;

  EnvironmentProfile copyWith({
    double? avgBrightness,
    double? brightnessVariance,
    double? detectionSuccessRate,
    double? frameLossRate,
    double? decodeErrorRate,
    int? samples,
  }) {
    return EnvironmentProfile(
      avgBrightness: avgBrightness ?? this.avgBrightness,
      brightnessVariance: brightnessVariance ?? this.brightnessVariance,
      detectionSuccessRate:
          detectionSuccessRate ?? this.detectionSuccessRate,
      frameLossRate: frameLossRate ?? this.frameLossRate,
      decodeErrorRate: decodeErrorRate ?? this.decodeErrorRate,
      samples: samples ?? this.samples,
    );
  }

  String get summary => 'brightness=${avgBrightness.toStringAsFixed(2)} '
      'var=${brightnessVariance.toStringAsFixed(3)} '
      'detect=${detectionSuccessRate.toStringAsFixed(2)} '
      'loss=${frameLossRate.toStringAsFixed(2)} '
      'decodeErr=${decodeErrorRate.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() => {
        'avgBrightness': avgBrightness,
        'brightnessVariance': brightnessVariance,
        'detectionSuccessRate': detectionSuccessRate,
        'frameLossRate': frameLossRate,
        'decodeErrorRate': decodeErrorRate,
        'samples': samples,
      };

  factory EnvironmentProfile.fromJson(Map<String, dynamic> json) {
    return EnvironmentProfile(
      avgBrightness: (json['avgBrightness'] as num?)?.toDouble() ?? 0.5,
      brightnessVariance:
          (json['brightnessVariance'] as num?)?.toDouble() ?? 0,
      detectionSuccessRate:
          (json['detectionSuccessRate'] as num?)?.toDouble() ?? 1.0,
      frameLossRate: (json['frameLossRate'] as num?)?.toDouble() ?? 0,
      decodeErrorRate: (json['decodeErrorRate'] as num?)?.toDouble() ?? 0,
      samples: json['samples'] as int? ?? 0,
    );
  }
}
