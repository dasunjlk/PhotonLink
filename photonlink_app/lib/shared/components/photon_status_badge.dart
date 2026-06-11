import 'package:flutter/material.dart';

import '../../ui/radii.dart';

/// Semantic intent of a [PhotonStatusBadge].
enum PhotonStatusTone { success, error, warning, info, neutral }

/// A compact pill that communicates a status with an icon + label.
class PhotonStatusBadge extends StatelessWidget {
  const PhotonStatusBadge({
    required this.label,
    super.key,
    this.tone = PhotonStatusTone.neutral,
    this.icon,
    this.compact = false,
  });

  final String label;
  final PhotonStatusTone tone;
  final IconData? icon;
  final bool compact;

  IconData get _defaultIcon => switch (tone) {
        PhotonStatusTone.success => Icons.check_circle_rounded,
        PhotonStatusTone.error => Icons.error_rounded,
        PhotonStatusTone.warning => Icons.warning_amber_rounded,
        PhotonStatusTone.info => Icons.info_rounded,
        PhotonStatusTone.neutral => Icons.circle,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final color = switch (tone) {
      PhotonStatusTone.neutral => scheme.onSurfaceVariant,
      _ => scheme.onSurface,
    };
    final fontWeight = switch (tone) {
      PhotonStatusTone.success => FontWeight.w700,
      PhotonStatusTone.error => FontWeight.w600,
      _ => FontWeight.w500,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.08),
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? _defaultIcon, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: (compact
                    ? theme.textTheme.labelSmall
                    : theme.textTheme.labelMedium)
                ?.copyWith(
              color: color,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }
}
