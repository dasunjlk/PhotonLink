import 'package:flutter/material.dart';

import '../../../transfer/reliability/models/transfer_diagnostics.dart';
import '../../../ui/spacing.dart';
import 'transfer_progress_bar.dart';

/// Live transfer diagnostics for sender/receiver screens.
class DiagnosticsPanel extends StatelessWidget {
  const DiagnosticsPanel({
    required this.diagnostics,
    required this.progress,
    required this.progressLabel,
    this.accentColor,
    this.missingCount = 0,
    super.key,
  });

  final TransferDiagnostics diagnostics;
  final double progress;
  final String progressLabel;
  final Color? accentColor;
  final int missingCount;

  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
    return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
  }

  String _formatEta(int? ms) {
    if (ms == null || ms <= 0) return '—';
    if (ms < 60000) return '${(ms / 1000).round()}s';
    return '${(ms / 60000).toStringAsFixed(1)} min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Transfer Diagnostics', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TransferProgressBar(
            progress: progress,
            label: progressLabel,
            accentColor: accentColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          _row('Packets sent', '${diagnostics.packetsSent}'),
          _row('Packets received', '${diagnostics.packetsReceived}'),
          _row('Missing', '$missingCount'),
          _row('Retries', '${diagnostics.retries}'),
          _row('Duplicates', '${diagnostics.duplicates}'),
          _row('Speed', _formatSpeed(diagnostics.throughputBytesPerSec)),
          _row('ETA', _formatEta(diagnostics.estimatedRemainingMs)),
          _row('Duration', '${diagnostics.durationMs} ms'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
