import '../models/adaptive_parameters.dart';
import '../models/adaptive_tiers.dart';
import '../models/capability_profile.dart';
import '../models/payload_density.dart';
import '../models/transport_profile.dart';

/// Maps abstract tiers to Color Matrix concrete values.
class ColorMatrixMappedParameters {
  const ColorMatrixMappedParameters({
    required this.gridSize,
    required this.bitsPerChannel,
    required this.framesPerSecond,
    required this.profile,
  });

  final int gridSize;
  final int bitsPerChannel;
  final double framesPerSecond;
  final TransportProfile profile;
}

class ColorMatrixParameterMapper {
  const ColorMatrixParameterMapper();

  static const gridSizes = [16, 24, 32, 48];

  ColorMatrixMappedParameters map(AdaptiveParameters params) {
    return ColorMatrixMappedParameters(
      gridSize: _gridSize(params.resolutionTier),
      bitsPerChannel: params.densityTier.bitsPerChannel,
      framesPerSecond: _fps(params.rateTier, params.profile),
      profile: params.profile,
    );
  }

  AdaptiveParameters fromManual({
    required int gridSize,
    required int bitsPerChannel,
    required double fps,
    TransportProfile profile = TransportProfile.balanced,
  }) {
    return AdaptiveParameters(
      profile: profile,
      resolutionTier: _tierFromGrid(gridSize),
      densityTier: PayloadDensity.fromBitsPerChannel(bitsPerChannel),
      rateTier: _tierFromFps(fps, profile),
    );
  }

  AdaptiveParameters initialFromCapability({
    required CapabilityProfile capability,
    double? lastQualityScore,
    TransportProfile profile = TransportProfile.balanced,
  }) {
    var resolution = ResolutionTier.medium;
    var rate = RateTier.normal;
    var density = PayloadDensity.medium;

    if (capability.deviceClass == DeviceClass.high) {
      resolution = ResolutionTier.large;
      rate = RateTier.fast;
    } else if (capability.deviceClass == DeviceClass.low) {
      // 16×16 cannot fit typical metadata frames (long file names).
      resolution = ResolutionTier.medium;
      rate = RateTier.slow;
      density = PayloadDensity.medium;
    }

    if (lastQualityScore != null) {
      if (lastQualityScore < 40) {
        resolution = resolution.stepDown();
        rate = rate.stepDown();
        density = density.stepDown();
        profile = TransportProfile.safe;
      } else if (lastQualityScore > 80) {
        resolution = resolution.stepUp();
        rate = rate.stepUp();
        profile = TransportProfile.performance;
      }
    }

    return AdaptiveParameters(
      profile: profile,
      resolutionTier: resolution,
      rateTier: rate,
      densityTier: density,
    );
  }

  int _gridSize(ResolutionTier tier) {
    final idx = tier.level.clamp(0, gridSizes.length - 1);
    // Minimum 24×24 — smaller grids cannot encode realistic metadata payloads.
    return gridSizes[idx] < 24 ? 24 : gridSizes[idx];
  }

  ResolutionTier _tierFromGrid(int size) {
    final idx = gridSizes.indexOf(size);
    if (idx < 0) return ResolutionTier.medium;
    return ResolutionTier.values[idx.clamp(0, 3)];
  }

  double _fps(RateTier tier, TransportProfile profile) {
    final base = switch (tier) {
      RateTier.slow => 1.5,
      RateTier.normal => 3.0,
      RateTier.fast => 5.0,
      RateTier.max => 8.0,
    };
    return switch (profile) {
      TransportProfile.safe => base * 0.75,
      TransportProfile.balanced => base,
      TransportProfile.performance => base * 1.25,
    }.clamp(1.0, 10.0);
  }

  RateTier _tierFromFps(double fps, TransportProfile profile) {
    final normalized = fps /
        switch (profile) {
          TransportProfile.safe => 0.75,
          TransportProfile.balanced => 1.0,
          TransportProfile.performance => 1.25,
        };
    if (normalized < 2) return RateTier.slow;
    if (normalized < 4) return RateTier.normal;
    if (normalized < 6.5) return RateTier.fast;
    return RateTier.max;
  }
}
