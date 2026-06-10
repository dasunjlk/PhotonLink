import 'models/adaptation_decision.dart';
export 'models/transport_profile.dart' show ProfileOverride, AdaptiveAggressiveness;
import 'models/adaptive_parameters.dart';
import 'models/environment_profile.dart';
import 'models/quality_score.dart';
import 'models/transport_profile.dart';
import 'payload_density_manager.dart';

/// Core adaptation decision engine with cooldown and hysteresis.
class AdaptationEngine {
  AdaptationEngine({
    this.cooldownMs = 5000,
    this.hysteresisSamples = 5,
    this.allowSessionParamChanges = false,
    PayloadDensityManager? densityManager,
  }) : _densityManager = densityManager ?? const PayloadDensityManager();

  final int cooldownMs;
  final int hysteresisSamples;
  final bool allowSessionParamChanges;
  final PayloadDensityManager _densityManager;

  AdaptiveParameters _current = const AdaptiveParameters();
  DateTime? _lastChangeAt;
  int _poorQualityStreak = 0;
  int _goodQualityStreak = 0;
  ProfileOverride _override = ProfileOverride.auto;
  bool _enabled = true;

  AdaptiveParameters get current => _current;

  void configure({
    required bool enabled,
    required ProfileOverride profileOverride,
    required AdaptiveAggressiveness aggressiveness,
  }) {
    _enabled = enabled;
    _override = profileOverride;
    // cooldown/hysteresis set at construction from aggressiveness
  }

  void setInitialParameters(AdaptiveParameters params) {
    _current = params;
    _lastChangeAt = null;
    _poorQualityStreak = 0;
    _goodQualityStreak = 0;
  }

  AdaptationDecision evaluate({
    required QualityScore qualityScore,
    required EnvironmentProfile environment,
    bool liveFpsOnly = false,
  }) {
    if (!_enabled) {
      return AdaptationDecision.noChange(_current);
    }

    final now = DateTime.now();
    if (_lastChangeAt != null &&
        now.difference(_lastChangeAt!).inMilliseconds < cooldownMs) {
      return AdaptationDecision.noChange(_current);
    }

    if (qualityScore.score < 50) {
      _poorQualityStreak++;
      _goodQualityStreak = 0;
    } else if (qualityScore.score > 75) {
      _goodQualityStreak++;
      _poorQualityStreak = 0;
    } else {
      _poorQualityStreak = 0;
      _goodQualityStreak = 0;
    }

    if (_poorQualityStreak < hysteresisSamples &&
        _goodQualityStreak < hysteresisSamples) {
      return AdaptationDecision.noChange(_current);
    }

    final previous = _current;
    var next = _current;
    var reason = '';

    if (_override.forcedProfile != null) {
      next = next.copyWith(profile: _override.forcedProfile!);
    } else if (_poorQualityStreak >= hysteresisSamples) {
      next = _degrade(next, environment);
      reason = 'quality low (${qualityScore.score.toStringAsFixed(0)})';
    } else if (_goodQualityStreak >= hysteresisSamples) {
      next = _improve(next, environment);
      reason = 'quality high (${qualityScore.score.toStringAsFixed(0)})';
    }

    if (liveFpsOnly) {
      // Mid-session: only adjust frame rate tier.
      if (next.rateTier != previous.rateTier) {
        _applyChange(next);
        return AdaptationDecision(
          applied: true,
          previous: previous,
          current: next,
          reason: reason.isEmpty ? 'fps adaptation' : reason,
          timestamp: now,
        );
      }
      return AdaptationDecision.noChange(_current);
    }

    if (!allowSessionParamChanges) {
      // Session-start only path — density/resolution decided at prepare.
      if (next.profile != previous.profile) {
        _applyChange(next);
        return AdaptationDecision(
          applied: true,
          previous: previous,
          current: next,
          reason: reason,
          timestamp: now,
        );
      }
      return AdaptationDecision.noChange(_current);
    }

    final newDensity = _densityManager.adjust(
      current: next.densityTier,
      environment: environment,
    );
    if (newDensity != next.densityTier) {
      next = next.copyWith(densityTier: newDensity);
      reason = reason.isEmpty ? 'density adjustment' : reason;
    }

    if (next != previous) {
      _applyChange(next);
      return AdaptationDecision(
        applied: true,
        previous: previous,
        current: next,
        reason: reason,
        timestamp: now,
      );
    }

    return AdaptationDecision.noChange(_current);
  }

  AdaptiveParameters _degrade(
    AdaptiveParameters params,
    EnvironmentProfile env,
  ) {
    var p = params;
    if (env.decodeErrorRate > 0.15 || env.frameLossRate > 0.2) {
      p = p.copyWith(
        rateTier: p.rateTier.stepDown(),
        densityTier: p.densityTier.stepDown(),
      );
      if (env.decodeErrorRate > 0.3) {
        p = p.copyWith(resolutionTier: p.resolutionTier.stepDown());
      }
      p = p.copyWith(profile: TransportProfile.safe);
    } else {
      p = p.copyWith(rateTier: p.rateTier.stepDown());
      p = p.copyWith(profile: TransportProfile.balanced);
    }
    return p;
  }

  AdaptiveParameters _improve(
    AdaptiveParameters params,
    EnvironmentProfile env,
  ) {
    if (env.decodeErrorRate > 0.05 || env.frameLossRate > 0.08) {
      return params;
    }
    return params.copyWith(
      rateTier: params.rateTier.stepUp(),
      profile: TransportProfile.performance,
    );
  }

  void _applyChange(AdaptiveParameters next) {
    _current = next;
    _lastChangeAt = DateTime.now();
    _poorQualityStreak = 0;
    _goodQualityStreak = 0;
  }

  void reset() {
    _current = const AdaptiveParameters();
    _lastChangeAt = null;
    _poorQualityStreak = 0;
    _goodQualityStreak = 0;
  }
}
