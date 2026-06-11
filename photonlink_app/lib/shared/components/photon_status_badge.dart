import 'package:flutter/material.dart';

import '../../ui/colors.dart';
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

  Color get _color => switch (tone) {
        PhotonStatusTone.success => AppColors.success,
        PhotonStatusTone.error => AppColors.error,
        PhotonStatusTone.warning => AppColors.warning,
        PhotonStatusTone.info => AppColors.info,
        PhotonStatusTone.neutral => AppColors.darkTextSecondary,
      };

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
    final color = _color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
