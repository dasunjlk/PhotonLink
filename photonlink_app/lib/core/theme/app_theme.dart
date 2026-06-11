import 'package:flutter/material.dart';

import '../../ui/colors.dart';
import '../../ui/radii.dart';
import '../../ui/spacing.dart';
import '../../ui/typography.dart';

/// Material 3 theme builders — strict monochrome palette.
///
/// Dark is the PhotonLink default: near-black surfaces, ash-gray cards,
/// white primary actions, and no chromatic accents.
abstract final class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.black,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.lightSurfaceElevated,
      onPrimaryContainer: AppColors.black,
      secondary: AppColors.ash,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.lightSurfaceElevated,
      onSecondaryContainer: AppColors.ashDark,
      tertiary: AppColors.ashLight,
      onTertiary: AppColors.black,
      error: AppColors.ashDark,
      onError: AppColors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.black,
      onSurfaceVariant: AppColors.ash,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.grayLight,
      surfaceContainerHighest: AppColors.lightSurfaceElevated,
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
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.white,
      onPrimary: AppColors.black,
      primaryContainer: AppColors.darkSurfaceHighest,
      onPrimaryContainer: AppColors.darkTextPrimary,
      secondary: AppColors.ashLight,
      onSecondary: AppColors.black,
      secondaryContainer: AppColors.darkSurfaceElevated,
      onSecondaryContainer: AppColors.darkTextSecondary,
      tertiary: AppColors.gray,
      onTertiary: AppColors.black,
      error: AppColors.grayLight,
      onError: AppColors.black,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.ashDark,
      surfaceContainerHighest: AppColors.darkSurfaceHighest,
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
    final isDark = brightness == Brightness.dark;

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
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
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
          foregroundColor: colorScheme.onSurface,
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
          foregroundColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.smRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.mdRadius),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.onSurface.withValues(alpha: 0.12),
        selectedIconTheme: IconThemeData(color: colorScheme.onSurface),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
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
          borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceElevated,
        selectedColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.04),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        checkmarkColor: colorScheme.onSurface,
        deleteIconColor: colorScheme.onSurfaceVariant,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.pillRadius,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.38);
            }
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onSurface;
            }
            return colorScheme.onSurfaceVariant;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onSurface.withValues(alpha: 0.12);
            }
            return Colors.transparent;
          }),
          side: WidgetStateProperty.all(BorderSide(color: border)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: AppRadii.mdRadius),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.onSurface,
        inactiveTrackColor: border,
        thumbColor: colorScheme.onSurface,
        overlayColor: colorScheme.onSurface.withValues(alpha: 0.08),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        space: 1,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.xlRadius),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? AppColors.darkSurfaceHighest
            : AppColors.lightSurfaceElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.mdRadius),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.onSurface,
        linearTrackColor: border,
      ),
      tooltipTheme: const TooltipThemeData(preferBelow: false),
    );
  }
}
