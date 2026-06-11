import 'package:flutter/material.dart';

/// Monochrome palette for PhotonLink — black, white, gray, and ash only.
///
/// Dark theme is the product default: near-black canvas, ash-gray cards,
/// high-contrast white text, and no chromatic accent colors.
abstract final class AppColors {
  // Core neutrals
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF141414);
  static const Color darkSurfaceElevated = Color(0xFF1C1C1C);
  static const Color darkSurfaceHighest = Color(0xFF242424);
  static const Color darkBorder = Color(0xFF2E2E2E);
  static const Color darkGlass = Color(0xCC141414);
  static const Color darkGlassBorder = Color(0x1FFFFFFF);

  // Ash / gray scale
  static const Color ashDark = Color(0xFF3A3A3A);
  static const Color ash = Color(0xFF6B6B6B);
  static const Color ashLight = Color(0xFF9A9A9A);
  static const Color gray = Color(0xFFB3B3B3);
  static const Color grayLight = Color(0xFFD4D4D4);

  // Text on dark
  static const Color darkTextPrimary = Color(0xFFF0F0F0);
  static const Color darkTextSecondary = Color(0xFFA3A3A3);
  static const Color darkTextTertiary = Color(0xFF6E6E6E);

  // Theme roles — all mapped to neutrals (no hue)
  static const Color primary = white;
  static const Color onPrimary = black;
  static const Color secondary = ashLight;
  static const Color accent = grayLight;
  static const Color success = Color(0xFFF5F5F5);
  static const Color warning = ashLight;
  static const Color error = grayLight;
  static const Color info = ash;

  // Light mode surfaces (grayscale only)
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = white;
  static const Color lightSurfaceElevated = Color(0xFFE8E8E8);
  static const Color lightBorder = Color(0xFFD4D4D4);
  static const Color lightGlass = Color(0xCCFFFFFF);
  static const Color lightGlassBorder = Color(0x22000000);

  // Background gradients — subtle black/ash shifts only
  static const List<Color> lightGradient = [
    Color(0xFFF5F5F5),
    Color(0xFFE8E8E8),
    Color(0xFFEDEDED),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF0A0A0A),
    Color(0xFF111111),
    Color(0xFF0D0D0D),
  ];

  static const List<Color> brandGradient = [
    ashDark,
    darkSurfaceElevated,
  ];

  // Transfer method accents — ash tiers (still monochrome)
  static const Color qrAccent = Color(0xFFE8E8E8);
  static const Color colorMatrixAccent = Color(0xFFC4C4C4);
  static const Color opticalStreamAccent = ashLight;
  static const Color audioAccent = ash;
  static const Color flashAccent = ashDark;
}
