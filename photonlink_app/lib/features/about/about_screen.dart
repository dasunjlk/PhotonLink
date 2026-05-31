import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bootstrap.dart';
import '../../core/constants.dart';
import '../../services/native_bridge/native_bridge.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/staggered_reveal.dart';
import '../../ui/spacing.dart';

/// About screen with app info and native bridge status.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packageInfo = ref.watch(packageInfoProvider);
    final nativeBridge = ref.watch(nativeBridgeProvider);

    return GradientScaffold(
      appBar: photonAppBar(context, title: 'About'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: StaggeredReveal(
            children: [
              GlassCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Version ${packageInfo.version} (${packageInfo.buildNumber})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'PhotonLink enables offline peer-to-peer file transfer '
                      'using optical communication methods — QR codes, color '
                      'matrices, and visual frame streams — without any '
                      'network connection.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Engine Status', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    _InfoRow(
                      label: 'Phase',
                      value: AppConstants.phaseLabel,
                    ),
                    _InfoRow(
                      label: 'Native Core',
                      value: 'Stub (Rust not connected)',
                    ),
                    FutureBuilder<String>(
                      future: nativeBridge.ping(),
                      builder: (context, snapshot) {
                        return _InfoRow(
                          label: 'Bridge Ping',
                          value: snapshot.data ?? 'Checking…',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Licensed under MIT. See LICENSE file in the repository.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
