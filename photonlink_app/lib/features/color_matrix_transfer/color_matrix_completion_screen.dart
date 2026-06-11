import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/components/components.dart';
import '../../shared/widgets/completion_hero.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/inner_screen_header.dart';
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
    final success = state.phase == TransferPhase.completed;
    final diag = state.diagnostics;

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            InnerScreenHeader(
              title: success ? 'Transfer Complete' : 'Transfer Failed',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        CompletionHero(
                          success: success,
                          title: success
                              ? 'Transfer Successful'
                              : 'Transfer Failed',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PhotonCard(
                          child: Column(
                            children: [
                              if (state.session != null) ...[
                                PhotonInfoTile(
                                  label: 'File',
                                  value: state.session!.fileName,
                                  dense: true,
                                ),
                                PhotonInfoTile(
                                  label: 'Chunks',
                                  value: '${state.totalChunks}',
                                  dense: true,
                                ),
                              ],
                              if (state.outputPath != null)
                                PhotonInfoTile(
                                  label: 'Saved to',
                                  value: state.outputPath!,
                                  dense: true,
                                ),
                              if (state.errorMessage != null)
                                PhotonInfoTile(
                                  label: 'Error',
                                  value: state.errorMessage!,
                                  dense: true,
                                ),
                              PhotonInfoTile(
                                label: 'Integrity',
                                dense: true,
                                valueWidget: PhotonStatusBadge(
                                  label: state.integrityValid == true
                                      ? 'Verified'
                                      : 'Failed',
                                  tone: state.integrityValid == true
                                      ? PhotonStatusTone.success
                                      : PhotonStatusTone.error,
                                  compact: true,
                                ),
                              ),
                              PhotonInfoTile(
                                label: 'Frames received',
                                value: '${diag.framesReceived}',
                                dense: true,
                              ),
                              PhotonInfoTile(
                                label: 'Corrupted',
                                value: '${diag.framesCorrupted}',
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PhotonButton(
                          label: 'Done',
                          icon: Icons.home_rounded,
                          onPressed: () => context.go('/'),
                        ),
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
