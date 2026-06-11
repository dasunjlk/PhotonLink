import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../shared/components/components.dart';
import '../../shared/widgets/completion_hero.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/inner_screen_header.dart';
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
                              ? 'File received successfully'
                              : 'Transfer failed',
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
                                  label: 'Size',
                                  value: '${state.session!.fileSize} bytes',
                                  dense: true,
                                ),
                              ],
                              PhotonInfoTile(
                                label: 'Integrity (SHA-256)',
                                dense: true,
                                valueWidget: PhotonStatusBadge(
                                  label: state.integrityValid == true
                                      ? 'Verified'
                                      : state.integrityValid == false
                                          ? 'Failed'
                                          : 'N/A',
                                  tone: state.integrityValid == true
                                      ? PhotonStatusTone.success
                                      : state.integrityValid == false
                                          ? PhotonStatusTone.error
                                          : PhotonStatusTone.neutral,
                                  compact: true,
                                ),
                              ),
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
                                label: 'Compression',
                                value: state.compression == CompressionType.none
                                    ? 'Off'
                                    : state.compression.id.toUpperCase(),
                                dense: true,
                              ),
                              PhotonInfoTile(
                                label: 'Encryption',
                                value:
                                    state.encryption == EncryptionMode.enabled
                                        ? 'ChaCha20-Poly1305'
                                        : 'Off',
                                dense: true,
                              ),
                              PhotonInfoTile(
                                label: 'Retries',
                                value: '${diag.retries}',
                                dense: true,
                              ),
                              PhotonInfoTile(
                                label: 'ACK / NAK',
                                value: '${diag.ackCount} / ${diag.nakCount}',
                                dense: true,
                              ),
                              PhotonInfoTile(
                                label: 'Duration',
                                value: '${diag.durationMs} ms',
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
