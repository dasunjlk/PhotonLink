import 'package:flutter/material.dart';

import '../../../protocols/interfaces/compression_type.dart';
import '../../../protocols/interfaces/encryption_mode.dart';
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
    this.compression = CompressionType.none,
    this.encryption = EncryptionMode.disabled,
    this.compressionSavingsBytes = 0,
    this.showExtended = true,
    super.key,
  });

  final TransferDiagnostics diagnostics;
  final double progress;
  final String progressLabel;
  final Color? accentColor;
  final int missingCount;
  final CompressionType compression;
  final EncryptionMode encryption;
  final int compressionSavingsBytes;
  final bool showExtended;

  String _formatSpeed(double bytesPerSec) {
    final speed = diagnostics.transferSpeedBytesPerSec > 0
        ? diagnostics.transferSpeedBytesPerSec
        : bytesPerSec;
    if (speed < 1024) return '${speed.toStringAsFixed(0)} B/s';
    return '${(speed / 1024).toStringAsFixed(1)} KB/s';
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
          Row(
            children: [
              Text('Transfer Diagnostics', style: theme.textTheme.titleSmall),
              const Spacer(),
              _chip(
                compression == CompressionType.none ? 'No compress' : compression.id,
                theme,
              ),
              const SizedBox(width: 4),
              _chip(
                encryption == EncryptionMode.enabled ? 'Encrypted' : 'No encrypt',
                theme,
              ),
            ],
          ),
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
          if (showExtended) ...[
            _row('ACK rounds', '${diagnostics.ackCount}'),
            _row('NAK rounds', '${diagnostics.nakCount}'),
            _row('Retries', '${diagnostics.retries}'),
            _row('Duplicates', '${diagnostics.duplicates}'),
            if (compressionSavingsBytes > 0)
              _row('Compression saved', '$compressionSavingsBytes B'),
            _row('Speed', _formatSpeed(diagnostics.throughputBytesPerSec)),
            _row('ETA', _formatEta(diagnostics.estimatedRemainingMs)),
            _row('Duration', '${diagnostics.durationMs} ms'),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
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
