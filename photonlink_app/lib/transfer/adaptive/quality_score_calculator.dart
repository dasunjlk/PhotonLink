import '../../protocols/interfaces/reliability/transfer_diagnostics.dart';
import 'models/environment_profile.dart';
import 'models/quality_score.dart';

/// Computes a 0–100 quality score from diagnostics and environment.
class QualityScoreCalculator {
  const QualityScoreCalculator();

  QualityScore calculate({
    required FrameDiagnostics diagnostics,
    required EnvironmentProfile environment,
  }) {
    final totalFrames = diagnostics.framesReceived +
        diagnostics.framesCorrupted +
        diagnostics.framesLost;
    final frameLossFactor = totalFrames == 0
        ? 100.0
        : (1.0 -
                (diagnostics.framesLost + diagnostics.missingPacketCount) /
                    (totalFrames + diagnostics.missingPacketCount + 1)) *
            100;

    final decodeTotal =
        diagnostics.framesReceived + diagnostics.framesCorrupted;
    final decodeErrorFactor = decodeTotal == 0
        ? 100.0
        : (diagnostics.framesReceived / decodeTotal) * 100;

    final retryFactor = diagnostics.framesRetried == 0
        ? 100.0
        : (100.0 - diagnostics.framesRetried.clamp(0, 20) * 3).clamp(0, 100);

    final detectionStabilityFactor =
        (environment.detectionSuccessRate * 0.6 +
                diagnostics.detectionAccuracy * 0.4) *
            100;

    final brightness = environment.avgBrightness;
    final brightnessFactor = brightness < 0.15 || brightness > 0.92
        ? 40.0
        : brightness < 0.25 || brightness > 0.85
            ? 70.0
            : 100.0;

    final score = (frameLossFactor * 0.25 +
            decodeErrorFactor * 0.30 +
            retryFactor * 0.10 +
            detectionStabilityFactor * 0.25 +
            brightnessFactor * 0.10)
        .clamp(0.0, 100.0);

    return QualityScore(
      score: score,
      frameLossFactor: frameLossFactor.clamp(0, 100).toDouble(),
      decodeErrorFactor: decodeErrorFactor.clamp(0, 100).toDouble(),
      retryFactor: retryFactor.clamp(0, 100).toDouble(),
      detectionStabilityFactor:
          detectionStabilityFactor.clamp(0, 100).toDouble(),
      brightnessFactor: brightnessFactor.clamp(0, 100).toDouble(),
    );
  }
}
