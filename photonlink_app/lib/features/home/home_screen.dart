import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/router/app_router.dart';
import '../../protocols/transfer_method.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/staggered_reveal.dart';
import '../../ui/motion.dart';
import '../../ui/spacing.dart';
import 'widgets/transfer_method_card.dart';

/// Main home screen with transfer method selection and navigation.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // Header row with History and Settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => context.push(AppRoutes.history),
                    icon: const Icon(Icons.history_rounded),
                    tooltip: 'History',
                  ),
                  IconButton.filledTonal(
                    onPressed: () => context.push(AppRoutes.analytics),
                    icon: const Icon(Icons.analytics_outlined),
                    tooltip: 'Analytics',
                  ),
                  IconButton.filledTonal(
                    onPressed: () => context.push(AppRoutes.settings),
                    icon: const Icon(Icons.settings_rounded),
                    tooltip: 'Settings',
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Title section
              StaggeredReveal(
                children: [
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppConstants.appTagline,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppConstants.phaseLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // Transfer method cards
              Expanded(
                child: ListView.separated(
                  itemCount: TransferMethod.homeMethods.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final method = TransferMethod.homeMethods[index];
                    return TransferMethodCard(
                      method: method,
                      onTap: method.isAvailable
                          ? () => context.push(
                                AppRoutes.transferSetupPath(method),
                              )
                          : null,
                    )
                        .animate(
                          delay: AppMotion.stagger * (index + 3),
                        )
                        .fadeIn(duration: AppMotion.normal)
                        .slideX(begin: 0.1, end: 0);
                  },
                ),
              ),

              // About link
              TextButton(
                onPressed: () => context.push(AppRoutes.about),
                child: const Text('About PhotonLink'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
