import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/reliability/transfer_diagnostics.dart';
import 'package:photonlink_app/transfer/adaptive/adaptation_engine.dart';
import 'package:photonlink_app/transfer/adaptive/environment_analyzer.dart';
import 'package:photonlink_app/transfer/adaptive/models/adaptive_parameters.dart';
import 'package:photonlink_app/transfer/adaptive/models/environment_profile.dart';
import 'package:photonlink_app/transfer/adaptive/models/quality_score.dart';
import 'package:photonlink_app/transfer/adaptive/quality_score_calculator.dart';

void main() {
  test('phase 6 adaptive overhead benchmark', () {
    const calculator = QualityScoreCalculator();
    final engine = AdaptationEngine(cooldownMs: 0, hysteresisSamples: 1);
    engine.setInitialParameters(const AdaptiveParameters());
    final envAnalyzer = EnvironmentAnalyzer();

    final sw = Stopwatch()..start();
    var decisions = 0;
    for (var i = 0; i < 1000; i++) {
      envAnalyzer.recordBrightness(0.4 + (i % 10) * 0.05);
      envAnalyzer.recordDetectionAttempt(success: i % 3 != 0);
      envAnalyzer.recordDecodeAttempt(success: i % 5 != 0);
      final env = envAnalyzer.current;
      final diag = FrameDiagnostics(
        framesReceived: i,
        framesCorrupted: i ~/ 10,
        detectionAccuracy: 0.8,
      );
      final score = calculator.calculate(
        diagnostics: diag,
        environment: env,
      );
      final d = engine.evaluate(
        qualityScore: score,
        environment: env,
        liveFpsOnly: i.isOdd,
      );
      if (d.applied) decisions++;
    }
    sw.stop();

    // ignore: avoid_print
    print('=== PhotonLink Phase 6 Adaptive Benchmarks ===');
    // ignore: avoid_print
    print('1000 evaluate cycles: ${sw.elapsedMicroseconds} µs');
    // ignore: avoid_print
    print('Decisions applied: $decisions');
    // ignore: avoid_print
    print('Avg per cycle: ${sw.elapsedMicroseconds / 1000} µs');

    expect(sw.elapsedMilliseconds, lessThan(500));
  });
}
