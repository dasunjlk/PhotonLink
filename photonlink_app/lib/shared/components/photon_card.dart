import 'package:flutter/material.dart';

import '../../ui/colors.dart';
import '../../ui/motion.dart';
import '../../ui/radii.dart';
import '../../ui/spacing.dart';

/// The foundational surface of the PhotonLink design system.
///
/// A rounded, dark-gray card with a subtle border. When [onTap] is provided
/// it gains pointer hover elevation and a gentle press-scale for tactile
/// feedback.
class PhotonCard extends StatefulWidget {
  const PhotonCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin = EdgeInsets.zero,
    this.borderRadius,
    this.accentColor,
    this.selected = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius? borderRadius;
  final Color? accentColor;
  final bool selected;
  final String? semanticLabel;

  @override
  State<PhotonCard> createState() => _PhotonCardState();
}

class _PhotonCardState extends State<PhotonCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = widget.borderRadius ?? AppRadii.lgRadius;
    final interactive = widget.onTap != null;

    final baseColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevatedColor =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;

    final borderColor = widget.selected
        ? theme.colorScheme.onSurface
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    final card = AnimatedScale(
      scale: _pressed ? 0.985 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.emphasis,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.emphasis,
        decoration: BoxDecoration(
          color: _hovered && interactive ? elevatedColor : baseColor,
          borderRadius: radius,
          border: Border.all(
            color: borderColor,
            width: widget.selected ? 1.5 : 1,
          ),
          boxShadow: _hovered && interactive
              ? [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );

    Widget content = card;
    if (interactive) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: ClipRRect(borderRadius: radius, child: card),
        ),
      );
    }

    content = Padding(padding: widget.margin, child: content);

    if (widget.semanticLabel != null) {
      content = Semantics(
        label: widget.semanticLabel,
        button: interactive,
        child: content,
      );
    }
    return content;
  }
}
