import 'dart:ui';

import 'package:flutter/material.dart';

import '../../ui/colors.dart';
import '../../ui/radii.dart';
import '../../ui/spacing.dart';

/// Glassmorphism-inspired card with backdrop blur and subtle border.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.accentColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadii.lgRadius;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: isDark ? AppColors.darkGlass : AppColors.lightGlass,
                  border: Border.all(
                    color: accentColor?.withValues(alpha: 0.3) ??
                        (isDark
                            ? AppColors.darkGlassBorder
                            : AppColors.lightGlassBorder),
                    width: 1,
                  ),
                  gradient: accentColor != null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor!.withValues(alpha: 0.08),
                            accentColor!.withValues(alpha: 0.02),
                          ],
                        )
                      : null,
                ),
                child: Padding(
                  padding: padding ??
                      const EdgeInsets.all(AppSpacing.cardPadding),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
