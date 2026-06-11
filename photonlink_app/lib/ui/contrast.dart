import 'package:flutter/material.dart';

import 'colors.dart';

/// Helpers for readable foreground/background pairs in the monochrome palette.
abstract final class AppContrast {
  /// Returns black or white depending on [background] luminance.
  static Color onBackground(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.light
        ? AppColors.black
        : AppColors.white;
  }

  /// Whether [foreground] has enough contrast on [background] for UI text.
  static bool isReadable(Color foreground, Color background) {
    return foreground.computeLuminance() - background.computeLuminance() > 0.15 ||
        background.computeLuminance() - foreground.computeLuminance() > 0.15;
  }

  /// Picks a readable foreground for [background], preferring theme roles.
  static Color readableOn(
    Color background, {
    required Color preferred,
    required Color fallback,
  }) {
    return isReadable(preferred, background) ? preferred : fallback;
  }
}
