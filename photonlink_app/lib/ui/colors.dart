import 'package:flutter/material.dart';

/// Central color palette and gradient definitions for PhotonLink.
///
/// The dark theme is the product default: a near-black canvas with
/// dark-gray cards, high-contrast text, and PhotonLink brand accents.
abstract final class AppColors {
  // Brand seed colors
  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFF06B6D4);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Light mode surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightGlass = Color(0xCCFFFFFF);
  static const Color lightGlassBorder = Color(0x22000000);

  // Dark mode surfaces — near-black canvas, dark-gray cards.
  static const Color darkBackground = Color(0xFF0A0A0C);
  static const Color darkSurface = Color(0xFF161619);
  static const Color darkSurfaceElevated = Color(0xFF1E1E23);
  static const Color darkSurfaceHighest = Color(0xFF26262C);
  static const Color darkBorder = Color(0xFF2C2C33);
  static const Color darkGlass = Color(0xCC161619);
  static const Color darkGlassBorder = Color(0x1FFFFFFF);

  // High-contrast text on dark
  static const Color darkTextPrimary = Color(0xFFF4F4F5);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextTertiary = Color(0xFF71717A);

  // Gradient stops for backgrounds
  static const List<Color> lightGradient = [
    Color(0xFFF8FAFC),
    Color(0xFFEEF2FF),
    Color(0xFFF0F9FF),
  ];

  // Subtle near-black gradient with a faint indigo/cyan wash.
  static const List<Color> darkGradient = [
    Color(0xFF0A0A0C),
    Color(0xFF0D0D14),
    Color(0xFF0A0E16),
  ];

  // Brand accent gradient for highlights and primary actions.
  static const List<Color> brandGradient = [primary, secondary];

  // Transfer method accent colors
  static const Color qrAccent = Color(0xFF6366F1);
  static const Color colorMatrixAccent = Color(0xFF8B5CF6);
  static const Color opticalStreamAccent = Color(0xFF06B6D4);
  static const Color audioAccent = Color(0xFF10B981);
  static const Color flashAccent = Color(0xFFF59E0B);
}
