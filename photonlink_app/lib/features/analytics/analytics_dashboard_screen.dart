import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/staggered_reveal.dart';
import '../../transfer/adaptive/adaptive_engine_providers.dart';
import '../../transfer/application/transfer_providers.dart';
import '../../ui/spacing.dart';

/// Live adaptive transfer analytics dashboard.
class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adaptive = ref.watch(adaptiveStateProvider);
    final receiver = ref.watch(colorMatrixReceiverControllerProvider);
    final diag = receiver.diagnostics;
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: photonAppBar(context, title: 'Transfer Analytics'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            StaggeredReveal(
            children: [
              const SectionHeader(
                title: 'Adaptive Engine',
                subtitle: 'Live transfer quality metrics',
              ),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _metricRow('Profile', adaptive.mapped.profile.id),
                    _metricRow(
                      'Matrix Size',
                      '${adaptive.mapped.gridSize}×${adaptive.mapped.gridSize}',
                    ),
                    _metricRow(
                      'Frame Rate',
                      '${adaptive.mapped.framesPerSecond.toStringAsFixed(1)} fps',
                    ),
                    _metricRow(
                      'Density',
                      adaptive.parameters.densityTier.id,
                    ),
                    _metricRow(
                      'Quality Score',
                      adaptive.qualityScore.score.toStringAsFixed(0),
                    ),
                    _metricRow(
                      'Throughput',
                      '${diag.throughputBytesPerSecond.toStringAsFixed(0)} B/s',
                    ),
                    _metricRow('Frame Loss', '${diag.framesLost}'),
                    _metricRow('Decode Errors', '${diag.framesCorrupted}'),
                    _metricRow(
                      'Detection',
                      '${(diag.detectionAccuracy * 100).toStringAsFixed(0)}%',
                    ),
                    if (adaptive.mismatchWarning != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        adaptive.mismatchWarning!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Environment'),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _metricRow(
                      'Brightness',
                      adaptive.environment.avgBrightness.toStringAsFixed(2),
                    ),
                    _metricRow(
                      'Variance',
                      adaptive.environment.brightnessVariance.toStringAsFixed(3),
                    ),
                    _metricRow(
                      'Detection Rate',
                      '${(adaptive.environment.detectionSuccessRate * 100).toStringAsFixed(0)}%',
                    ),
                    _metricRow(
                      'Decode Error Rate',
                      '${(adaptive.environment.decodeErrorRate * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),
              if (adaptive.lighting.showOverlay) ...[
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Lighting'),
                GlassCard(
                  child: Text(adaptive.lighting.hint),
                ),
              ],
            ],
          ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
