import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/components/components.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/inner_screen_header.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            const InnerScreenHeader(title: 'Transfer Analytics'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PhotonSectionHeader(
                          title: 'Adaptive Engine',
                          subtitle: 'Live transfer quality metrics',
                          icon: Icons.auto_awesome_rounded,
                        ),
                        PhotonCard(
                          child: Column(
                            children: [
                              PhotonInfoTile(
                                  label: 'Profile',
                                  value: adaptive.mapped.profile.id,
                                  dense: true,),
                              PhotonInfoTile(
                                  label: 'Matrix Size',
                                  value:
                                      '${adaptive.mapped.gridSize}×${adaptive.mapped.gridSize}',
                                  dense: true,),
                              PhotonInfoTile(
                                  label: 'Frame Rate',
                                  value:
                                      '${adaptive.mapped.framesPerSecond.toStringAsFixed(1)} fps',
                                  dense: true,),
                              PhotonInfoTile(
                                  label: 'Density',
                                  value: adaptive.parameters.densityTier.id,
                                  dense: true,),
                              PhotonInfoTile(
                                label: 'Quality Score',
                                dense: true,
                                valueWidget: PhotonStatusBadge(
                                  label: adaptive.qualityScore.score
                                      .toStringAsFixed(0),
                                  tone: adaptive.qualityScore.score >= 75
                                      ? PhotonStatusTone.success
                                      : adaptive.qualityScore.score >= 50
                                          ? PhotonStatusTone.warning
                                          : PhotonStatusTone.error,
                                  compact: true,
                                ),
                              ),
                              PhotonInfoTile(
                                  label: 'Throughput',
                                  value:
                                      '${diag.throughputBytesPerSecond.toStringAsFixed(0)} B/s',
                                  dense: true,),
                              PhotonInfoTile(
                                  label: 'Frame Loss',
                                  value: '${diag.framesLost}',
                                  dense: true,),
                              PhotonInfoTile(
                                  label: 'Decode Errors',
                                  value: '${diag.framesCorrupted}',
                                  dense: true,),
                              PhotonInfoTile(
                                  label: 'Detection',
                                  value:
                                      '${(diag.detectionAccuracy * 100).toStringAsFixed(0)}%',
                                  dense: true,),
                            ],
                          ),
                        ),
                        if (adaptive.mismatchWarning != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          PhotonCard(
                            accentColor: theme.colorScheme.onSurfaceVariant,
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: theme.colorScheme.onSurfaceVariant,),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                    child: Text(adaptive.mismatchWarning!),),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        const PhotonSectionHeader(
                          title: 'Environment',
                          icon: Icons.thermostat_rounded,
                        ),
                        PhotonCard(
                          child: Column(
                            children: [
                              PhotonInfoTile(
                                  label: 'Brightness',
                                  value: adaptive.environment.avgBrightness
                                      .toStringAsFixed(2),
                                  dense: true,),
                              PhotonInfoTile(
                                  label: 'Variance',
                                  value: adaptive.environment.brightnessVariance
                                      .toStringAsFixed(3),
                                  dense: true,),
                              PhotonInfoTile(
                                  label: 'Detection Rate',
                                  value:
                                      '${(adaptive.environment.detectionSuccessRate * 100).toStringAsFixed(0)}%',
                                  dense: true,),
                              PhotonInfoTile(
                                  label: 'Decode Error Rate',
                                  value:
                                      '${(adaptive.environment.decodeErrorRate * 100).toStringAsFixed(1)}%',
                                  dense: true,),
                            ],
                          ),
                        ),
                        if (adaptive.lighting.showOverlay) ...[
                          const SizedBox(height: AppSpacing.lg),
                          const PhotonSectionHeader(
                            title: 'Lighting',
                            icon: Icons.wb_sunny_outlined,
                          ),
                          PhotonCard(child: Text(adaptive.lighting.hint)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
