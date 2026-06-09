import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/adaptive/adaptation_diagnostics.dart';
import 'package:photonlink_app/transfer/adaptive/models/adaptation_decision.dart';
import 'package:photonlink_app/transfer/adaptive/models/adaptive_parameters.dart';
import 'package:photonlink_app/transfer/adaptive/models/adaptive_tiers.dart';
import 'package:photonlink_app/transfer/adaptive/models/quality_score.dart';

void main() {
  test('records parameter changes and quality history', () {
    final diag = AdaptationDiagnostics();
    diag.recordDecision(
      AdaptationDecision(
        applied: true,
        previous: const AdaptiveParameters(rateTier: RateTier.fast),
        current: const AdaptiveParameters(rateTier: RateTier.normal),
        reason: 'test',
        timestamp: DateTime(2026, 1, 1),
      ),
    );
    diag.recordQualityScore(const QualityScore(score: 72));

    expect(diag.events.length, 1);
    expect(diag.events.first.parameter, 'rateTier');
    expect(diag.qualityHistory.length, 1);
    expect(diag.appliedDecisionCount, 1);
    expect(diag.exportJson(), contains('rateTier'));
  });
}
