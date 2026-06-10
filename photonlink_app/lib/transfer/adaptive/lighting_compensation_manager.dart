import 'models/environment_profile.dart';

/// Lighting recommendations — no hardware control.
class LightingRecommendation {
  const LightingRecommendation({
    this.brightnessAdjustment = 0,
    this.contrastAdjustment = 0,
    this.hint = '',
    this.showOverlay = false,
  });

  final double brightnessAdjustment;
  final double contrastAdjustment;
  final String hint;
  final bool showOverlay;
}

class LightingCompensationManager {
  const LightingCompensationManager();

  LightingRecommendation recommend(EnvironmentProfile environment) {
    final b = environment.avgBrightness;
    final v = environment.brightnessVariance;

    if (b < 0.2) {
      return const LightingRecommendation(
        brightnessAdjustment: 0.3,
        contrastAdjustment: 0.1,
        hint: 'Increase ambient lighting or reduce glare on the display',
        showOverlay: true,
      );
    }
    if (b > 0.88) {
      return const LightingRecommendation(
        brightnessAdjustment: -0.2,
        contrastAdjustment: 0.15,
        hint: 'Reduce screen brightness or move to shaded area',
        showOverlay: true,
      );
    }
    if (v > 0.08) {
      return const LightingRecommendation(
        contrastAdjustment: 0.2,
        hint: 'Lighting is unstable — hold devices steady',
        showOverlay: true,
      );
    }
    return const LightingRecommendation();
  }
}
