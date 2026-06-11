import 'package:flutter/material.dart';

import '../../ui/colors.dart';
import '../../ui/radii.dart';

/// A rounded, tonal icon button used across the PhotonLink chrome
/// (history / settings / back / filter actions).
class PhotonIconButton extends StatelessWidget {
  const PhotonIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.accentColor,
    this.filled = true,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? accentColor;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = accentColor ?? theme.colorScheme.onSurface;

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: filled
            ? (isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceElevated)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdRadius,
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.46, color: accent),
          ),
        ),
      ),
    );
  }
}
