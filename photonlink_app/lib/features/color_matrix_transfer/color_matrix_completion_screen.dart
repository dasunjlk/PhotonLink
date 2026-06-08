import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/animated_pill_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../transfer/application/color_matrix_transfer_state.dart';
import '../../ui/spacing.dart';

/// Completion screen for Color Matrix transfers.
class ColorMatrixCompletionScreen extends StatelessWidget {
  const ColorMatrixCompletionScreen({
    required this.state,
    super.key,
  });

  final ColorMatrixReceiverState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = state.phase == TransferPhase.completed;

    return GradientScaffold(
      appBar: photonAppBar(context, title: 'Transfer Complete'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 80,
                color: success
                    ? Colors.greenAccent
                    : theme.colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                success ? 'Transfer Successful' : 'Transfer Failed',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.session != null) ...[
                      _row('File', state.session!.fileName),
                      _row('Chunks', '${state.totalChunks}'),
                    ],
                    if (state.outputPath != null)
                      _row('Saved to', state.outputPath!),
                    if (state.errorMessage != null)
                      _row('Error', state.errorMessage!),
                    _row(
                      'Integrity',
                      state.integrityValid == true ? 'Verified' : 'Failed',
                    ),
                    _row(
                      'Frames received',
                      '${state.diagnostics.framesReceived}',
                    ),
                    _row(
                      'Corrupted',
                      '${state.diagnostics.framesCorrupted}',
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
