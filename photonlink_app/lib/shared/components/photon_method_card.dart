import 'package:flutter/material.dart';

import '../../protocols/transfer_method.dart';
import '../../ui/radii.dart';
import '../../ui/spacing.dart';
import 'photon_card.dart';
import 'photon_status_badge.dart';

/// A transport-method card (QR, Color Matrix, Optical Stream).
///
/// Renders as a vertical icon + name + description tile that adapts:
/// in a horizontal row on wide layouts and stacked on mobile. Tapping a
/// card opens the corresponding method screen.
class PhotonMethodCard extends StatelessWidget {
  const PhotonMethodCard({
    required this.method,
    super.key,
    this.onTap,
    this.compact = false,
  });

  final TransferMethod method;
  final VoidCallback? onTap;

  /// When true uses a horizontal row layout (good for narrow/stacked lists).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = method.accentColor;
    final disabled = !method.isAvailable;

    final badge = method.isPreview
        ? const PhotonStatusBadge(
            label: 'Preview',
            tone: PhotonStatusTone.info,
            icon: Icons.science_rounded,
            compact: true,
          )
        : disabled
            ? const PhotonStatusBadge(
                label: 'Soon',
                tone: PhotonStatusTone.neutral,
                icon: Icons.lock_clock_rounded,
                compact: true,
              )
            : null;

    final iconBox = Container(
      width: compact ? 52 : 60,
      height: compact ? 52 : 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.28),
            accent.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Icon(method.icon, color: accent, size: compact ? 26 : 30),
    );

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: PhotonCard(
        onTap: onTap,
        accentColor: accent,
        semanticLabel: '${method.displayName}. ${method.description}',
        child: compact
            ? Row(
                children: [
                  iconBox,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _textBlock(theme, badge, false)),
                  const Icon(Icons.chevron_right_rounded),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [iconBox, if (badge != null) badge],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _textBlock(theme, null, true),
                ],
              ),
      ),
    );
  }

  Widget _textBlock(ThemeData theme, Widget? badge, bool vertical) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                method.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badge != null) ...[const SizedBox(width: AppSpacing.sm), badge],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          method.description,
          maxLines: vertical ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
