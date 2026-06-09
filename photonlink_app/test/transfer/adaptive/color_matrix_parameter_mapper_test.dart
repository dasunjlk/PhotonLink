import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/adaptive/models/adaptive_parameters.dart';
import 'package:photonlink_app/transfer/adaptive/models/adaptive_tiers.dart';
import 'package:photonlink_app/transfer/adaptive/models/capability_profile.dart';
import 'package:photonlink_app/transfer/adaptive/models/payload_density.dart';
import 'package:photonlink_app/transfer/adaptive/models/transport_profile.dart';
import 'package:photonlink_app/transfer/adaptive/parameter_mappers/color_matrix_parameter_mapper.dart';

void main() {
  const mapper = ColorMatrixParameterMapper();

  test('maps tiers to concrete values', () {
    final mapped = mapper.map(
      const AdaptiveParameters(
        resolutionTier: ResolutionTier.large,
        densityTier: PayloadDensity.high,
        rateTier: RateTier.fast,
        profile: TransportProfile.balanced,
      ),
    );
    expect(mapped.gridSize, 32);
    expect(mapped.bitsPerChannel, 3);
    expect(mapped.framesPerSecond, greaterThan(3));
  });

  test('initialFromCapability respects device class', () {
    final high = mapper.initialFromCapability(
      capability: const CapabilityProfile(deviceClass: DeviceClass.high),
    );
    expect(high.resolutionTier.level, greaterThanOrEqualTo(ResolutionTier.medium.level));

    final low = mapper.initialFromCapability(
      capability: const CapabilityProfile(deviceClass: DeviceClass.low),
    );
    expect(low.resolutionTier.level, lessThanOrEqualTo(ResolutionTier.medium.level));
  });

  test('supports 48x48 grid', () {
    final mapped = mapper.map(
      const AdaptiveParameters(resolutionTier: ResolutionTier.extraLarge),
    );
    expect(mapped.gridSize, 48);
  });
}
