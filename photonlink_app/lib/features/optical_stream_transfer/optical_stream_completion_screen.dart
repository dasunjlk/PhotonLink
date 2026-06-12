import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/components/components.dart';
import '../../shared/widgets/completion_hero.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/inner_screen_header.dart';
import '../../transfer/application/optical_stream_transfer_state.dart';
import '../../ui/spacing.dart';

/// Completion screen for Optical Stream transfers.
class OpticalStreamCompletionScreen extends StatelessWidget {
  const OpticalStreamCompletionScreen({
    required this.state,
    super.key,
  });

  final OpticalStreamReceiverState state;

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
                              ? 'Stream Transfer Successful'
                              : 'Stream Transfer Failed',
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
                                label: 'Recovered packets',
                                value: '${state.recoveredPackets}',
                                dense: true,
                              ),
                              PhotonInfoTile(
                                label: 'Dropped frames',
                                value: '${state.droppedFrames}',
                                dense: true,
                              ),
                              PhotonInfoTile(
                                label: 'Throughput',
                                value:
                                    '${diag.throughputBytesPerSecond.toStringAsFixed(0)} B/s',
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PhotonButton(
                          label: 'Done',
                          icon: Icons.check_rounded,
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
