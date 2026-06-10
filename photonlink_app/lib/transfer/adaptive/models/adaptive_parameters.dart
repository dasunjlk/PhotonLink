import 'adaptive_tiers.dart';
import 'payload_density.dart';
import 'transport_profile.dart';

/// Transport-agnostic adaptive parameter tiers.
class AdaptiveParameters {
  const AdaptiveParameters({
    this.profile = TransportProfile.balanced,
    this.rateTier = RateTier.normal,
    this.densityTier = PayloadDensity.medium,
    this.resolutionTier = ResolutionTier.medium,
  });

  final TransportProfile profile;
  final RateTier rateTier;
  final PayloadDensity densityTier;
  final ResolutionTier resolutionTier;

  AdaptiveParameters copyWith({
    TransportProfile? profile,
    RateTier? rateTier,
    PayloadDensity? densityTier,
    ResolutionTier? resolutionTier,
  }) {
    return AdaptiveParameters(
      profile: profile ?? this.profile,
      rateTier: rateTier ?? this.rateTier,
      densityTier: densityTier ?? this.densityTier,
      resolutionTier: resolutionTier ?? this.resolutionTier,
    );
  }

  Map<String, dynamic> toJson() => {
        'profile': profile.id,
        'rateTier': rateTier.level,
        'densityTier': densityTier.id,
        'resolutionTier': resolutionTier.level,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveParameters &&
          profile == other.profile &&
          rateTier == other.rateTier &&
          densityTier == other.densityTier &&
          resolutionTier == other.resolutionTier;

  @override
  int get hashCode =>
      Object.hash(profile, rateTier, densityTier, resolutionTier);

  factory AdaptiveParameters.fromJson(Map<String, dynamic> json) {
    return AdaptiveParameters(
      profile: TransportProfile.fromId(json['profile'] as String?),
      rateTier: RateTier.values.firstWhere(
        (t) => t.level == (json['rateTier'] as int? ?? 1),
        orElse: () => RateTier.normal,
      ),
      densityTier: PayloadDensity.fromId(json['densityTier'] as String?),
      resolutionTier: ResolutionTier.values.firstWhere(
        (t) => t.level == (json['resolutionTier'] as int? ?? 1),
        orElse: () => ResolutionTier.medium,
      ),
    );
  }
}
