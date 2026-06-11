import 'package:flutter/material.dart';

import '../../../ui/spacing.dart';

/// Linear progress indicator with label for transfer progress.
class TransferProgressBar extends StatelessWidget {
  const TransferProgressBar({
    required this.progress,
    required this.label,
    this.accentColor,
    super.key,
  });

  final double progress;
  final String label;

  /// Kept for API compatibility; bar color uses [ColorScheme.onSurface].
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = scheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              '${(progress.clamp(0, 1) * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelLarge?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 8,
            backgroundColor: scheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }
}
