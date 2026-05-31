import 'package:flutter/material.dart';

import '../../ui/radii.dart';
import '../../ui/spacing.dart';

/// Pill-shaped button with optional icon and gradient fill.
class AnimatedPillButton extends StatelessWidget {
  const AnimatedPillButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.color,
    this.isOutlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.pillRadius),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.pillRadius),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}
