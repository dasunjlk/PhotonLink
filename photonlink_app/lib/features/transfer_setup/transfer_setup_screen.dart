import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../protocols/transfer_method.dart';
import '../../shared/widgets/animated_pill_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/staggered_reveal.dart';
import '../../ui/spacing.dart';

/// Screen for choosing Send or Receive before starting a transfer.
class TransferSetupScreen extends StatelessWidget {
  const TransferSetupScreen({
    required this.method,
    super.key,
  });

  final TransferMethod method;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: photonAppBar(context, title: method.displayName),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: StaggeredReveal(
            children: [
              GlassCard(
                accentColor: method.accentColor,
                child: Row(
                  children: [
                    Icon(method.icon, color: method.accentColor, size: 40),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.displayName,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            method.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              const SectionHeader(
                title: 'Choose Direction',
                subtitle: 'Send a file or receive one from another device',
              ),
              AnimatedPillButton(
                label: 'Send File',
                icon: Icons.upload_rounded,
                color: method.accentColor,
                onPressed: () => context.push(
                  '${AppRoutes.pick}?method=${method.routeName}',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedPillButton(
                label: 'Receive File',
                icon: Icons.download_rounded,
                color: method.accentColor,
                isOutlined: true,
                onPressed: () => context.push(
                  '${AppRoutes.scan}?method=${method.routeName}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
