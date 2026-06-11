import 'package:flutter/material.dart';

import '../../ui/radii.dart';
import '../../ui/spacing.dart';

/// Visual emphasis levels for [PhotonButton].
enum PhotonButtonVariant { primary, secondary, ghost, danger }

/// Sizing presets for [PhotonButton].
enum PhotonButtonSize { medium, large }

/// The standard PhotonLink action button.
///
/// Modern, rounded, with optional leading [icon], variant-based emphasis,
/// touch-friendly sizing, and an optional [expand] to fill its width.
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
  final Color? accentColor;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ??
        (variant == PhotonButtonVariant.danger
            ? theme.colorScheme.error
            : theme.colorScheme.primary);

    final padding = EdgeInsets.symmetric(
      horizontal:
          size == PhotonButtonSize.large ? AppSpacing.xl : AppSpacing.lg,
      vertical:
          size == PhotonButtonSize.large ? AppSpacing.md + 4 : AppSpacing.md,
    );
    final shape = RoundedRectangleBorder(borderRadius: AppRadii.mdRadius);
    final enabled = onPressed != null && !loading;

    final child = _content(context);

    final Widget button = switch (variant) {
      PhotonButtonVariant.primary || PhotonButtonVariant.danger => FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: accent.withValues(alpha: 0.30),
            disabledForegroundColor: Colors.white70,
            padding: padding,
            shape: shape,
          ),
          child: child,
        ),
      PhotonButtonVariant.secondary => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent.withValues(alpha: 0.5)),
            padding: padding,
            shape: shape,
          ),
          child: child,
        ),
      PhotonButtonVariant.ghost => TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: accent,
            padding: padding,
            shape: shape,
          ),
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _content(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
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
