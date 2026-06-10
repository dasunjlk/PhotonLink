import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/reliability/transfer_diagnostics.dart';
import 'package:photonlink_app/transfer/adaptive/models/environment_profile.dart';
import 'package:photonlink_app/transfer/adaptive/quality_score_calculator.dart';

void main() {
  const calculator = QualityScoreCalculator();

  test('perfect conditions yield high score', () {
    final score = calculator.calculate(
      diagnostics: const FrameDiagnostics(
        framesReceived: 100,
        detectionAccuracy: 0.95,
      ),
      environment: const EnvironmentProfile(
        detectionSuccessRate: 0.95,
        avgBrightness: 0.5,
      ),
    );
    expect(score.score, greaterThan(80));
  });

  test('poor decode and loss yield low score', () {
    final score = calculator.calculate(
      diagnostics: const FrameDiagnostics(
        framesReceived: 10,
        framesCorrupted: 40,
        framesLost: 20,
        missingPacketCount: 15,
      ),
      environment: const EnvironmentProfile(
        detectionSuccessRate: 0.3,
        decodeErrorRate: 0.5,
        avgBrightness: 0.1,
      ),
    );
    expect(score.score, lessThan(60));
  });
}
