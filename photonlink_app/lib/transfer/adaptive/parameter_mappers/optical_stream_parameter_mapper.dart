import '../models/adaptive_parameters.dart';
import '../models/adaptive_tiers.dart';
import '../models/capability_profile.dart';
import '../models/payload_density.dart';
import '../models/transport_profile.dart';
import 'color_matrix_parameter_mapper.dart';

/// Maps abstract tiers to Optical Stream concrete values.
class OpticalStreamParameterMapper {
  const OpticalStreamParameterMapper();

  static const gridSizes = [24, 32, 40, 48];

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
    required double fps,
    TransportProfile profile = TransportProfile.balanced,
  }) {
    return AdaptiveParameters(
      profile: profile,
      resolutionTier: _tierFromGrid(gridSize),
      densityTier: PayloadDensity.medium,
      rateTier: _tierFromFps(fps, profile),
    );
  }

  AdaptiveParameters initialFromCapability({
    required CapabilityProfile capability,
    double? lastQualityScore,
    TransportProfile profile = TransportProfile.balanced,
  }) {
    var resolution = ResolutionTier.medium;
    var rate = RateTier.fast;
    const density = PayloadDensity.medium;

    if (capability.deviceClass == DeviceClass.high) {
      resolution = ResolutionTier.large;
      rate = RateTier.max;
    } else if (capability.deviceClass == DeviceClass.low) {
      resolution = ResolutionTier.medium;
      rate = RateTier.normal;
    }

    if (lastQualityScore != null) {
      if (lastQualityScore < 40) {
        resolution = resolution.stepDown();
        rate = rate.stepDown();
      } else if (lastQualityScore > 80) {
        resolution = resolution.stepUp();
        rate = rate.stepUp();
      }
    }

    return AdaptiveParameters(
      profile: profile,
      resolutionTier: resolution,
      densityTier: density,
      rateTier: rate,
    );
  }

  int _gridSize(ResolutionTier tier) {
    return switch (tier) {
      ResolutionTier.small => 24,
      ResolutionTier.medium => 32,
      ResolutionTier.large => 40,
      ResolutionTier.extraLarge => 48,
    };
  }

  double _fps(RateTier tier, TransportProfile profile) {
    final base = switch (tier) {
      RateTier.slow => 4.0,
      RateTier.normal => 6.0,
      RateTier.fast => 8.0,
      RateTier.max => 12.0,
    };
    return switch (profile) {
      TransportProfile.safe => base * 0.75,
      TransportProfile.performance => base * 1.15,
      _ => base,
    };
  }

  ResolutionTier _tierFromGrid(int gridSize) {
    if (gridSize >= 48) return ResolutionTier.extraLarge;
    if (gridSize >= 40) return ResolutionTier.large;
    if (gridSize >= 32) return ResolutionTier.medium;
    return ResolutionTier.small;
  }

  RateTier _tierFromFps(double fps, TransportProfile profile) {
    final adjusted = switch (profile) {
      TransportProfile.safe => fps / 0.75,
      TransportProfile.performance => fps / 1.15,
      _ => fps,
    };
    if (adjusted >= 10) return RateTier.max;
    if (adjusted >= 7) return RateTier.fast;
    if (adjusted >= 5) return RateTier.normal;
    return RateTier.slow;
  }
}
