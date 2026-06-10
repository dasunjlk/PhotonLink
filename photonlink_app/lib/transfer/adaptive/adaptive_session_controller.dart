import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../protocols/interfaces/reliability/transfer_diagnostics.dart';
import '../../settings/application/settings_controller.dart';
import 'adaptation_diagnostics.dart';
import 'adaptation_engine.dart';
import 'models/adaptation_decision.dart';
import 'adaptive_state.dart';
import 'device_capability_detector.dart';
import 'environment_analyzer.dart';
import 'lighting_compensation_manager.dart';
import 'models/adaptive_parameters.dart';
import 'models/adaptive_tiers.dart';
import 'models/transport_profile.dart';
import 'parameter_mappers/color_matrix_parameter_mapper.dart';
import 'quality_score_calculator.dart';

/// Orchestrates adaptive engine components for a transfer session.
class AdaptiveSessionController {
  AdaptiveSessionController({
    required this.ref,
    DeviceCapabilityDetector? capabilityDetector,
    EnvironmentAnalyzer? environmentAnalyzer,
    QualityScoreCalculator? qualityCalculator,
    LightingCompensationManager? lightingManager,
    ColorMatrixParameterMapper? mapper,
    AdaptationDiagnostics? diagnostics,
  })  : _capabilityDetector =
            capabilityDetector ?? DeviceCapabilityDetector(),
        _environment = environmentAnalyzer ?? EnvironmentAnalyzer(),
        _qualityCalculator =
            qualityCalculator ?? const QualityScoreCalculator(),
        _lighting = lightingManager ?? const LightingCompensationManager(),
        _mapper = mapper ?? const ColorMatrixParameterMapper(),
        _adaptDiagnostics = diagnostics ?? AdaptationDiagnostics();

  final Ref ref;
  final DeviceCapabilityDetector _capabilityDetector;
  final EnvironmentAnalyzer _environment;
  final QualityScoreCalculator _qualityCalculator;
  final LightingCompensationManager _lighting;
  final ColorMatrixParameterMapper _mapper;
  final AdaptationDiagnostics _adaptDiagnostics;

  AdaptationEngine _senderEngine = AdaptationEngine();
  AdaptationEngine _receiverEngine =
      AdaptationEngine(allowSessionParamChanges: true);
  AdaptiveState _state = const AdaptiveState();
  double? _lastSessionQualityScore;

  AdaptiveState get state => _state;
  AdaptationDiagnostics get diagnostics => _adaptDiagnostics;

  Future<void> initializeSession({
    int cameraWidth = 0,
    int cameraHeight = 0,
    bool isReceiver = false,
  }) async {
    final settings = ref.read(settingsProvider);
    final aggressiveness = settings.adaptiveAggressiveness;

    _senderEngine = AdaptationEngine(
      cooldownMs: aggressiveness.cooldownMs,
      hysteresisSamples: aggressiveness.hysteresisSamples,
      allowSessionParamChanges: false,
    );
    _receiverEngine = AdaptationEngine(
      cooldownMs: aggressiveness.cooldownMs,
      hysteresisSamples: aggressiveness.hysteresisSamples,
      allowSessionParamChanges: true,
    );

    final capability = await _capabilityDetector.detect(
      cameraWidth: cameraWidth,
      cameraHeight: cameraHeight,
      cameraResolutionPreset: settings.cameraResolution,
    );

    _environment.reset();
    _adaptDiagnostics.reset();

    _lastSessionQualityScore ??=
        ref.read(settingsRepositoryProvider).loadLastQualityScore();

    AdaptiveParameters initial;
    if (settings.adaptiveModeEnabled) {
      final profile = settings.profileOverride.forcedProfile ??
          TransportProfile.fromId(settings.colorTransportQuality);
      initial = _mapper.initialFromCapability(
        capability: capability,
        lastQualityScore: _lastSessionQualityScore,
        profile: profile,
      );
      if (settings.profileOverride.forcedProfile != null) {
        initial = initial.copyWith(profile: settings.profileOverride.forcedProfile!);
      }
    } else {
      initial = _mapper.fromManual(
        gridSize: settings.colorMatrixSize,
        bitsPerChannel: settings.colorBitsPerChannel,
        fps: settings.colorTransferFrameRate,
        profile: TransportProfile.fromId(settings.colorTransportQuality),
      );
    }

    _senderEngine.setInitialParameters(initial);
    _receiverEngine.setInitialParameters(initial);

    final mapped = _mapper.map(initial);
    _state = AdaptiveState(
      capability: capability,
      parameters: initial,
      mapped: mapped,
      isActive: settings.adaptiveModeEnabled,
      processingThrottleMs: _throttleForTier(initial),
    );
  }

  ColorMatrixMappedParameters getSessionStartParams() => _state.mapped;

  void recordBrightness(double avg, {double variance = 0}) {
    _environment.recordBrightness(avg);
    if (variance > 0) {
      // Fold variance into environment via extra brightness samples spread.
      _environment.recordBrightness((avg + variance).clamp(0, 1));
    }
    _refreshEnvironment();
  }

  void recordDetection({required bool success, required double accuracy}) {
    _environment.recordDetectionAttempt(success: success);
    _refreshFromDiagnostics(
      FrameDiagnostics(detectionAccuracy: accuracy),
    );
  }

  void recordDecode({required bool success, required FrameDiagnostics diag}) {
    _environment.recordDecodeAttempt(success: success);
    _refreshFromDiagnostics(diag);
  }

  void _refreshFromDiagnostics(FrameDiagnostics diag) {
    final env = _environment.current;
    final quality = _qualityCalculator.calculate(
      diagnostics: diag,
      environment: env,
    );
    _adaptDiagnostics.recordQualityScore(quality);
    _adaptDiagnostics.recordEnvironment(env);

    final engine = _receiverEngine;
    engine.configure(
      enabled: ref.read(settingsProvider).adaptiveModeEnabled,
      profileOverride: ref.read(settingsProvider).profileOverride,
      aggressiveness: ref.read(settingsProvider).adaptiveAggressiveness,
    );

    final decision = engine.evaluate(
      qualityScore: quality,
      environment: env,
      liveFpsOnly: false,
    );
    _adaptDiagnostics.recordDecision(decision);

    var params = decision.current;
    var mapped = _mapper.map(params);
    var throttle = _throttleForTier(params);
    var lighting = _lighting.recommend(env);

    if (decision.applied) {
      throttle = _throttleForTier(params);
    }

    _state = _state.copyWith(
      environment: env,
      qualityScore: quality,
      parameters: params,
      mapped: mapped,
      lighting: lighting,
      lastDecision: decision,
      processingThrottleMs: throttle,
    );
  }

  AdaptationDecision evaluateSenderFps(FrameDiagnostics diag) {
    final env = _environment.current;
    final quality = _qualityCalculator.calculate(
      diagnostics: diag,
      environment: env,
    );

    _senderEngine.configure(
      enabled: ref.read(settingsProvider).adaptiveModeEnabled,
      profileOverride: ref.read(settingsProvider).profileOverride,
      aggressiveness: ref.read(settingsProvider).adaptiveAggressiveness,
    );

    final decision = _senderEngine.evaluate(
      qualityScore: quality,
      environment: env,
      liveFpsOnly: true,
    );
    _adaptDiagnostics.recordDecision(decision);

    if (decision.applied) {
      final mapped = _mapper.map(decision.current);
      _state = _state.copyWith(
        parameters: decision.current,
        mapped: mapped,
        qualityScore: quality,
        lastDecision: decision,
      );
    }

    return decision;
  }

  Future<void> finalizeSession() async {
    _lastSessionQualityScore = _state.qualityScore.score;
    await ref
        .read(settingsRepositoryProvider)
        .saveLastQualityScore(_state.qualityScore.score);
  }

  void _refreshEnvironment() {
    final env = _environment.current;
    _adaptDiagnostics.recordEnvironment(env);
    _state = _state.copyWith(
      environment: env,
      lighting: _lighting.recommend(env),
    );
  }

  int _throttleForTier(AdaptiveParameters params) {
    return switch (params.rateTier) {
      RateTier.slow => 400,
      RateTier.normal => 250,
      RateTier.fast => 180,
      RateTier.max => 120,
    };
  }

  void reset() {
    _environment.reset();
    _adaptDiagnostics.reset();
    _senderEngine.reset();
    _receiverEngine.reset();
    _state = const AdaptiveState();
  }
}
