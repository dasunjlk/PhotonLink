import 'package:flutter/material.dart';

import '../../ui/colors.dart';
import '../../ui/radii.dart';
import '../../ui/spacing.dart';
import '../../ui/typography.dart';

/// Material 3 theme builders for light and dark modes.
///
/// Dark is the PhotonLink default: near-black surfaces, dark-gray cards,
/// high-contrast text, and indigo/violet/cyan brand accents.
abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      surface: AppColors.lightSurface,
    );

    return _buildTheme(
      colorScheme,
      Brightness.light,
      scaffold: AppColors.lightBackground,
      card: AppColors.lightSurface,
      border: AppColors.lightBorder,
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      surface: AppColors.darkSurface,
      surfaceContainerHighest: AppColors.darkSurfaceHighest,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder,
      error: AppColors.error,
    );

    return _buildTheme(
      colorScheme,
      Brightness.dark,
      scaffold: AppColors.darkBackground,
      card: AppColors.darkSurface,
      border: AppColors.darkBorder,
    );
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    Brightness brightness, {
    required Color scaffold,
    required Color card,
    required Color border,
  }) {
    final textTheme = AppTypography.textTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffold,
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.lgRadius,
          side: BorderSide(color: border),
        ),
        color: card,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.mdRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.mdRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadii.smRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadii.mdRadius),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.pillRadius,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        space: 1,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: brightness == Brightness.dark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.xlRadius),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.mdRadius),
      ),
      tooltipTheme: const TooltipThemeData(preferBelow: false),
    );
  }
}
