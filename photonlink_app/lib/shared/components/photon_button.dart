import 'package:flutter/material.dart';

import '../../ui/radii.dart';
import '../../ui/spacing.dart';

/// Visual emphasis levels for [PhotonButton].
enum PhotonButtonVariant { primary, secondary, ghost, danger }

/// Sizing presets for [PhotonButton].
enum PhotonButtonSize { medium, large }

/// The standard PhotonLink action button.
///
/// Uses theme [ColorScheme] pairs so labels stay readable in dark and light
/// modes. The optional [accentColor] is ignored — contrast is theme-driven.
class PhotonButton extends StatelessWidget {
  const PhotonButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.variant = PhotonButtonVariant.primary,
    this.size = PhotonButtonSize.medium,
    this.accentColor,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PhotonButtonVariant variant;
  final PhotonButtonSize size;

  /// Kept for API compatibility; styling uses [ThemeData.colorScheme] only.
  final Color? accentColor;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (Color bg, Color fg, Color? border) = switch (variant) {
      PhotonButtonVariant.primary => (
          scheme.primary,
          scheme.onPrimary,
          null,
        ),
      PhotonButtonVariant.danger => (
          scheme.surfaceContainerHighest,
          scheme.onSurface,
          scheme.outline,
        ),
      PhotonButtonVariant.secondary => (
          Colors.transparent,
          scheme.onSurface,
          scheme.outline,
        ),
      PhotonButtonVariant.ghost => (
          Colors.transparent,
          scheme.onSurfaceVariant,
          null,
        ),
    };

    final padding = EdgeInsets.symmetric(
      horizontal:
          size == PhotonButtonSize.large ? AppSpacing.xl : AppSpacing.lg,
      vertical:
          size == PhotonButtonSize.large ? AppSpacing.md + 4 : AppSpacing.md,
    );
    final shape = RoundedRectangleBorder(borderRadius: AppRadii.mdRadius);
    final enabled = onPressed != null && !loading;

    final child = _content(fg);

    final Widget button = switch (variant) {
      PhotonButtonVariant.primary || PhotonButtonVariant.danger => FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: bg.withValues(alpha: 0.35),
            disabledForegroundColor: fg.withValues(alpha: 0.45),
            padding: padding,
            shape: shape,
            side: border != null ? BorderSide(color: border) : null,
          ),
          child: child,
        ),
      PhotonButtonVariant.secondary => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: fg,
            side: BorderSide(color: border ?? scheme.outline),
            padding: padding,
            shape: shape,
          ),
          child: child,
        ),
      PhotonButtonVariant.ghost => TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: fg,
            padding: padding,
            shape: shape,
          ),
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _content(Color foreground) {
    if (loading) {
      return SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: foreground,
        ),
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
