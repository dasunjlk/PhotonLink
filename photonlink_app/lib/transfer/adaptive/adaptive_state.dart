import 'models/adaptation_decision.dart';
import 'models/adaptive_parameters.dart';
import 'models/capability_profile.dart';
import 'models/environment_profile.dart';
import 'models/quality_score.dart';
import 'models/transport_profile.dart';
import 'lighting_compensation_manager.dart';
import 'parameter_mappers/color_matrix_parameter_mapper.dart';

/// Live adaptive engine state exposed to UI and controllers.
class AdaptiveState {
  const AdaptiveState({
    this.capability = const CapabilityProfile(),
    this.environment = const EnvironmentProfile(),
    this.qualityScore = QualityScore.unknown,
    this.parameters = const AdaptiveParameters(),
    this.mapped = const ColorMatrixMappedParameters(
      gridSize: 24,
      bitsPerChannel: 2,
      framesPerSecond: 4,
      profile: TransportProfile.balanced,
    ),
    this.lighting = const LightingRecommendation(),
    this.lastDecision,
    this.isActive = false,
    this.processingThrottleMs = 200,
    this.mismatchWarning,
  });

  final CapabilityProfile capability;
  final EnvironmentProfile environment;
  final QualityScore qualityScore;
  final AdaptiveParameters parameters;
  final ColorMatrixMappedParameters mapped;
  final LightingRecommendation lighting;
  final AdaptationDecision? lastDecision;
  final bool isActive;
  final int processingThrottleMs;
  final String? mismatchWarning;

  AdaptiveState copyWith({
    CapabilityProfile? capability,
    EnvironmentProfile? environment,
    QualityScore? qualityScore,
    AdaptiveParameters? parameters,
    ColorMatrixMappedParameters? mapped,
    LightingRecommendation? lighting,
    AdaptationDecision? lastDecision,
    bool? isActive,
    int? processingThrottleMs,
    String? mismatchWarning,
  }) {
    return AdaptiveState(
      capability: capability ?? this.capability,
      environment: environment ?? this.environment,
      qualityScore: qualityScore ?? this.qualityScore,
      parameters: parameters ?? this.parameters,
      mapped: mapped ?? this.mapped,
      lighting: lighting ?? this.lighting,
      lastDecision: lastDecision ?? this.lastDecision,
      isActive: isActive ?? this.isActive,
      processingThrottleMs: processingThrottleMs ?? this.processingThrottleMs,
      mismatchWarning: mismatchWarning,
    );
  }
}
