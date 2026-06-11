import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../ui/motion.dart';
import '../../ui/spacing.dart';

/// Animated success / failure hero used on completion screens.
class CompletionHero extends StatelessWidget {
  const CompletionHero({
    required this.success,
    required this.title,
    super.key,
    this.subtitle,
  });

  final bool success;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color =
        success ? scheme.onSurface : scheme.onSurfaceVariant;

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outline, width: 2),
          ),
          child: Icon(
            success ? Icons.check_rounded : Icons.close_rounded,
            size: 52,
            color: color,
          ),
        )
            .animate()
            .scale(duration: AppMotion.normal, curve: Curves.easeOutBack)
            .fadeIn(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
