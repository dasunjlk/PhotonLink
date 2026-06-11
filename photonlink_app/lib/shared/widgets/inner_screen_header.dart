import 'package:flutter/material.dart';

import '../../ui/spacing.dart';
import '../components/photon_back_button.dart';

/// Consistent top bar for inner screens: a back button on the left, the
/// screen title centered, and optional trailing actions on the right.
///
/// Mirrors the wireframe (back arrow top-left, title centered) while staying
/// responsive — the title stays centered regardless of action count.
class InnerScreenHeader extends StatelessWidget {
  const InnerScreenHeader({
    required this.title,
    super.key,
    this.actions = const [],
    this.subtitle,
    this.onBack,
  });

  final String title;
  final List<Widget> actions;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          PhotonBackButton(onPressed: onBack),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (actions.isEmpty)
            const SizedBox(width: 44)
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i != 0) const SizedBox(width: AppSpacing.sm),
                  actions[i],
                ],
              ],
            ),
        ],
      ),
    );
  }
}
