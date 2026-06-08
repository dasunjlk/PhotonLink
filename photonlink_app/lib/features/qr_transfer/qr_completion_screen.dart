import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/animated_pill_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../transfer/application/transfer_state.dart';
import '../../ui/spacing.dart';

/// Shows transfer success or failure with integrity result.
class QrCompletionScreen extends StatelessWidget {
  const QrCompletionScreen({
    required this.state,
    super.key,
  });

  final ReceiverTransferState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = state.phase == TransferPhase.completed;
    final color = success ? Colors.green : theme.colorScheme.error;

    return GradientScaffold(
      appBar: photonAppBar(
        context,
        title: success ? 'Transfer Complete' : 'Transfer Failed',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                success ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 80,
                color: color,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                success ? 'File received successfully' : 'Transfer failed',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.session != null) ...[
                      _row('File', state.session!.fileName),
                      _row('Size', '${state.session!.fileSize} bytes'),
                    ],
                    _row(
                      'SHA-256',
                      state.integrityValid == true
                          ? 'Verified'
                          : state.integrityValid == false
                              ? 'Failed'
                              : 'N/A',
                    ),
                    if (state.outputPath != null)
                      _row('Saved to', state.outputPath!),
                    if (state.errorMessage != null)
                      _row('Error', state.errorMessage!),
                    if (state.duplicatesIgnored > 0)
                      _row('Duplicates ignored', '${state.duplicatesIgnored}'),
                    _row(
                      'Compression',
                      state.compression == CompressionType.none
                          ? 'Off'
                          : state.compression.id,
                    ),
                    _row(
                      'Encryption',
                      state.encryption == EncryptionMode.enabled
                          ? 'ChaCha20-Poly1305'
                          : 'Off',
                    ),
                    if (state.compressionSavingsBytes > 0)
                      _row(
                        'Compression saved',
                        '${state.compressionSavingsBytes} B',
                      ),
                    _row('Retries', '${state.diagnostics.retries}'),
                    _row('ACK / NAK', '${state.diagnostics.ackCount} / ${state.diagnostics.nakCount}'),
                    _row('Duration', '${state.diagnostics.durationMs} ms'),
                    _row(
                      'Throughput',
                      '${state.diagnostics.throughputBytesPerSec.toStringAsFixed(0)} B/s',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AnimatedPillButton(
                label: 'Done',
                icon: Icons.home_rounded,
                color: theme.colorScheme.primary,
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}
