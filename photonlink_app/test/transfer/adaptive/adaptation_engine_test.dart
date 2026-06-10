import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/adaptive/adaptation_engine.dart';
import 'package:photonlink_app/transfer/adaptive/models/adaptive_parameters.dart';
import 'package:photonlink_app/transfer/adaptive/models/adaptive_tiers.dart';
import 'package:photonlink_app/transfer/adaptive/models/environment_profile.dart';
import 'package:photonlink_app/transfer/adaptive/models/payload_density.dart';
import 'package:photonlink_app/transfer/adaptive/models/quality_score.dart';
import 'package:photonlink_app/transfer/adaptive/models/transport_profile.dart';

void main() {
  test('cooldown blocks rapid changes', () {
    final engine = AdaptationEngine(
      cooldownMs: 10000,
      hysteresisSamples: 1,
    );
    engine.setInitialParameters(const AdaptiveParameters(rateTier: RateTier.normal));

    final poor = const QualityScore(score: 30);
    final env = const EnvironmentProfile(decodeErrorRate: 0.4);

    final first = engine.evaluate(qualityScore: poor, environment: env, liveFpsOnly: true);
    expect(first.applied, isTrue);

    final second = engine.evaluate(qualityScore: poor, environment: env, liveFpsOnly: true);
    expect(second.applied, isFalse);
  });

  test('hysteresis prevents oscillation', () {
    final engine = AdaptationEngine(
      cooldownMs: 0,
      hysteresisSamples: 5,
    );
    engine.setInitialParameters(const AdaptiveParameters());

    final borderline = const QualityScore(score: 45);
    final env = const EnvironmentProfile();

    for (var i = 0; i < 4; i++) {
      final d = engine.evaluate(
        qualityScore: borderline,
        environment: env,
        liveFpsOnly: true,
      );
      expect(d.applied, isFalse);
    }
  });

  test('live fps degrades on poor quality', () {
    final engine = AdaptationEngine(
      cooldownMs: 0,
      hysteresisSamples: 1,
    );
    engine.setInitialParameters(
      const AdaptiveParameters(rateTier: RateTier.fast),
    );

    final decision = engine.evaluate(
      qualityScore: const QualityScore(score: 25),
      environment: const EnvironmentProfile(decodeErrorRate: 0.3),
      liveFpsOnly: true,
    );

    expect(decision.applied, isTrue);
    expect(decision.current.rateTier.level, lessThan(RateTier.fast.level));
  });

  test('profile override forces safe mode', () {
    final engine = AdaptationEngine(cooldownMs: 0, hysteresisSamples: 1);
    engine.configure(
      enabled: true,
      profileOverride: ProfileOverride.safe,
      aggressiveness: AdaptiveAggressiveness.normal,
    );
    engine.setInitialParameters(
      const AdaptiveParameters(profile: TransportProfile.performance),
    );

    final decision = engine.evaluate(
      qualityScore: const QualityScore(score: 80),
      environment: const EnvironmentProfile(),
    );

    expect(decision.current.profile, TransportProfile.safe);
  });

  test('density steps down on high error rate', () {
    final engine = AdaptationEngine(
      cooldownMs: 0,
      hysteresisSamples: 1,
      allowSessionParamChanges: true,
    );
    engine.setInitialParameters(
      const AdaptiveParameters(densityTier: PayloadDensity.high),
    );

    final decision = engine.evaluate(
      qualityScore: const QualityScore(score: 30),
      environment: const EnvironmentProfile(
        decodeErrorRate: 0.4,
        frameLossRate: 0.3,
      ),
    );

    expect(decision.applied, isTrue);
    expect(decision.current.densityTier, isNot(PayloadDensity.high));
  });
}
