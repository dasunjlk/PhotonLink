import '../fec/models/fec_configuration.dart';
import '../fec/models/fec_profile.dart';
import 'models/environment_profile.dart';
import 'models/quality_score.dart';

/// Adaptive FEC recommendation types.
enum FecRecommendation {
  increaseRedundancy,
  decreaseRedundancy,
  adjustStrategy,
  noChange,
}

/// Recommends FEC configuration adjustments based on quality and environment.
class FecAdaptationPolicy {
  const FecAdaptationPolicy();

  FecRecommendation evaluate({
    required FecConfiguration current,
    required QualityScore qualityScore,
    required EnvironmentProfile environment,
  }) {
    if (!current.enabled) return FecRecommendation.noChange;

    if (qualityScore.score < 50 ||
        environment.frameLossRate > 0.15 ||
        environment.decodeErrorRate > 0.15) {
      return FecRecommendation.increaseRedundancy;
    }

    if (qualityScore.score > 80 &&
        environment.frameLossRate < 0.05 &&
        environment.decodeErrorRate < 0.05) {
      return FecRecommendation.decreaseRedundancy;
    }

    if (environment.frameLossRate > 0.08) {
      return FecRecommendation.adjustStrategy;
    }

    return FecRecommendation.noChange;
  }

  FecConfiguration applyRecommendation({
    required FecConfiguration current,
    required FecRecommendation recommendation,
  }) {
    if (recommendation == FecRecommendation.noChange) return current;

    final profiles = [
      FecProfile.lowProtection,
      FecProfile.balanced,
      FecProfile.highProtection,
      FecProfile.maximumReliability,
    ];

    var profile = current.profile;
    if (profile == FecProfile.auto) {
      profile = FecProfile.balanced;
    }

    final currentIndex = profiles.indexOf(profile);
    if (currentIndex < 0) return current;

    switch (recommendation) {
      case FecRecommendation.increaseRedundancy:
        final next = (currentIndex + 1).clamp(0, profiles.length - 1);
        return current.copyWith(
          profile: profiles[next],
          redundancyPercent: profiles[next].defaultRedundancyPercent,
        );
      case FecRecommendation.decreaseRedundancy:
        final prev = (currentIndex - 1).clamp(0, profiles.length - 1);
        return current.copyWith(
          profile: profiles[prev],
          redundancyPercent: profiles[prev].defaultRedundancyPercent,
        );
      case FecRecommendation.adjustStrategy:
        return current.copyWith(blockSize: (current.blockSize - 2).clamp(4, 20));
      case FecRecommendation.noChange:
        return current;
    }
  }
}
