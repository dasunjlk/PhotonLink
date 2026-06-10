import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/adaptive/lighting_compensation_manager.dart';
import 'package:photonlink_app/transfer/adaptive/models/environment_profile.dart';

void main() {
  const manager = LightingCompensationManager();

  test('recommends more light when dark', () {
    final rec = manager.recommend(
      const EnvironmentProfile(avgBrightness: 0.1),
    );
    expect(rec.showOverlay, isTrue);
    expect(rec.brightnessAdjustment, greaterThan(0));
  });

  test('no overlay in normal conditions', () {
    final rec = manager.recommend(
      const EnvironmentProfile(avgBrightness: 0.5, brightnessVariance: 0.01),
    );
    expect(rec.showOverlay, isFalse);
  });
}
