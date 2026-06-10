import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/adaptive/models/environment_profile.dart';
import 'package:photonlink_app/transfer/adaptive/models/payload_density.dart';
import 'package:photonlink_app/transfer/adaptive/payload_density_manager.dart';

void main() {
  const manager = PayloadDensityManager();

  test('steps down on high error rate', () {
    final result = manager.adjust(
      current: PayloadDensity.high,
      environment: const EnvironmentProfile(
        decodeErrorRate: 0.3,
        frameLossRate: 0.2,
      ),
    );
    expect(result, PayloadDensity.medium);
  });

  test('steps up on clean environment', () {
    final result = manager.adjust(
      current: PayloadDensity.low,
      environment: const EnvironmentProfile(
        decodeErrorRate: 0.01,
        detectionSuccessRate: 0.95,
      ),
    );
    expect(result, PayloadDensity.medium);
  });
}
