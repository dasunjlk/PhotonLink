import 'package:flutter/material.dart';

/// Central color palette and gradient definitions for PhotonLink.
abstract final class AppColors {
  // Brand seed colors
  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFF06B6D4);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Light mode surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGlass = Color(0xCCFFFFFF);
  static const Color lightGlassBorder = Color(0x33FFFFFF);

  // Dark mode surfaces
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkGlass = Color(0x661E293B);
  static const Color darkGlassBorder = Color(0x33FFFFFF);

  // Gradient stops for backgrounds
  static const List<Color> lightGradient = [
    Color(0xFFF8FAFC),
    Color(0xFFEEF2FF),
    Color(0xFFF0F9FF),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF0F172A),
    Color(0xFF1E1B4B),
    Color(0xFF0C4A6E),
  ];

  // Transfer method accent colors
  static const Color qrAccent = Color(0xFF6366F1);
  static const Color colorMatrixAccent = Color(0xFF8B5CF6);
  static const Color opticalStreamAccent = Color(0xFF06B6D4);
  static const Color audioAccent = Color(0xFF10B981);
  static const Color flashAccent = Color(0xFFF59E0B);
}
