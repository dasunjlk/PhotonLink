import 'models/environment_profile.dart';
import 'models/payload_density.dart';

/// Maps and adjusts payload density based on error rates.
class PayloadDensityManager {
  const PayloadDensityManager();

  PayloadDensity adjust({
    required PayloadDensity current,
    required EnvironmentProfile environment,
  }) {
    final errorRate = environment.decodeErrorRate;
    final lossRate = environment.frameLossRate;
    final combined = errorRate * 0.6 + lossRate * 0.4;

    if (combined > 0.25) return current.stepDown();
    if (combined > 0.12) {
      return current == PayloadDensity.high
          ? PayloadDensity.medium
          : current;
    }
    if (combined < 0.03 && environment.detectionSuccessRate > 0.9) {
      return current.stepUp();
    }
    return current;
  }

  int bitsPerChannel(PayloadDensity density) => density.bitsPerChannel;
}
