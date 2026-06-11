import 'package:flutter/material.dart';

import '../../ui/spacing.dart';

/// A label / value row for information and diagnostics panels.
///
/// Optionally renders a leading [icon] and a value that can be plain text
/// (via [value]) or any custom [valueWidget] (e.g. a status badge).
class PhotonInfoTile extends StatelessWidget {
  const PhotonInfoTile({
    required this.label,
    super.key,
    this.value,
    this.valueWidget,
    this.icon,
    this.accentColor,
    this.dense = false,
  }) : assert(value != null || valueWidget != null,
            'Provide either value or valueWidget',);

  final String label;
  final String? value;
  final Widget? valueWidget;
  final IconData? icon;
  final Color? accentColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: dense ? AppSpacing.xs : AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: accentColor ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (valueWidget != null)
            valueWidget!
          else
            Flexible(
              child: Text(
                value!,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
