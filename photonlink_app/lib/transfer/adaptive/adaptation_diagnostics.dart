import 'dart:convert';

import 'models/adaptation_decision.dart';
import 'models/adaptive_parameters.dart';
import 'models/environment_profile.dart';
import 'models/quality_score.dart';

/// Records adaptation decisions and parameter history.
class AdaptationDiagnostics {
  AdaptationDiagnostics();

  final List<AdaptiveEvent> events = [];
  final List<QualityScoreSnapshot> qualityHistory = [];
  final List<EnvironmentSnapshot> environmentHistory = [];

  AdaptiveParameters? lastParameters;
  int decisionCount = 0;
  int appliedDecisionCount = 0;

  void recordDecision(AdaptationDecision decision) {
    decisionCount++;
    if (decision.applied) appliedDecisionCount++;
    lastParameters = decision.current;

    if (decision.applied) {
      final ts = decision.timestamp ?? DateTime.now();
      if (decision.previous.profile != decision.current.profile) {
        events.add(AdaptiveEvent(
          timestamp: ts,
          parameter: 'profile',
          fromValue: decision.previous.profile.id,
          toValue: decision.current.profile.id,
          reason: decision.reason,
        ));
      }
      if (decision.previous.rateTier != decision.current.rateTier) {
        events.add(AdaptiveEvent(
          timestamp: ts,
          parameter: 'rateTier',
          fromValue: decision.previous.rateTier.level.toString(),
          toValue: decision.current.rateTier.level.toString(),
          reason: decision.reason,
        ));
      }
      if (decision.previous.densityTier != decision.current.densityTier) {
        events.add(AdaptiveEvent(
          timestamp: ts,
          parameter: 'densityTier',
          fromValue: decision.previous.densityTier.id,
          toValue: decision.current.densityTier.id,
          reason: decision.reason,
        ));
      }
      if (decision.previous.resolutionTier !=
          decision.current.resolutionTier) {
        events.add(AdaptiveEvent(
          timestamp: ts,
          parameter: 'resolutionTier',
          fromValue: decision.previous.resolutionTier.level.toString(),
          toValue: decision.current.resolutionTier.level.toString(),
          reason: decision.reason,
        ));
      }
    }
  }

  void recordQualityScore(QualityScore score) {
    qualityHistory.add(QualityScoreSnapshot(
      timestamp: DateTime.now(),
      score: score,
    ));
    if (qualityHistory.length > 200) qualityHistory.removeAt(0);
  }

  void recordEnvironment(EnvironmentProfile env) {
    environmentHistory.add(EnvironmentSnapshot(
      timestamp: DateTime.now(),
      profile: env,
    ));
    if (environmentHistory.length > 200) environmentHistory.removeAt(0);
  }

  void reset() {
    events.clear();
    qualityHistory.clear();
    environmentHistory.clear();
    lastParameters = null;
    decisionCount = 0;
    appliedDecisionCount = 0;
  }

  Map<String, dynamic> toJson() => {
        'events': events.map((e) => e.toJson()).toList(),
        'qualityHistory':
            qualityHistory.map((q) => q.toJson()).toList(),
        'environmentHistory':
            environmentHistory.map((e) => e.toJson()).toList(),
        'lastParameters': lastParameters?.toJson(),
        'decisionCount': decisionCount,
        'appliedDecisionCount': appliedDecisionCount,
      };

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class QualityScoreSnapshot {
  QualityScoreSnapshot({required this.timestamp, required this.score});

  final DateTime timestamp;
  final QualityScore score;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        ...score.toJson(),
      };
}

class EnvironmentSnapshot {
  EnvironmentSnapshot({required this.timestamp, required this.profile});

  final DateTime timestamp;
  final EnvironmentProfile profile;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        ...profile.toJson(),
      };
}
