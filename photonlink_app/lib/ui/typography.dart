import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale using Inter font family.
abstract final class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final base = GoogleFonts.interTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    );

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
