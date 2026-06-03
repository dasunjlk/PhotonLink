import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../protocols/transfer_method.dart';
import '../../services/permissions/permission_service.dart';
import '../../shared/widgets/animated_pill_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/scan_frame_overlay.dart';
import '../../shared/widgets/staggered_reveal.dart';
import '../../transfer/application/sender_controller.dart';
import '../../transfer/application/transfer_providers.dart';
import '../../transfer/application/transfer_state.dart';
import '../../ui/spacing.dart';
import 'widgets/diagnostics_panel.dart';
import 'widgets/qr_frame_display.dart';

/// Bidirectional QR sender: display + scan for ACK/NAK/handshake.
class QrSenderScreen extends ConsumerStatefulWidget {
  const QrSenderScreen({super.key});

  @override
  ConsumerState<QrSenderScreen> createState() => _QrSenderScreenState();
}

class _QrSenderScreenState extends ConsumerState<QrSenderScreen> {
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final _permission = PermissionService();
  bool _cameraOk = false;
  PlatformFile? _file;

  @override
  void initState() {
    super.initState();
    _initCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(senderControllerProvider.notifier).checkResumableSession();
    });
  }

  Future<void> _initCamera() async {
    try {
      await _permission.ensureCamera();
      if (mounted) setState(() => _cameraOk = true);
    } catch (_) {
      if (mounted) setState(() => _cameraOk = false);
    }
  }

  @override
  void dispose() {
    ref.read(senderControllerProvider.notifier).reset();
    _scanner.dispose();
    super.dispose();
  }

  bool _showDisplay(TransferPhase phase) => phase.showsQrDisplay;

  bool _showScan(TransferPhase phase) =>
      phase == TransferPhase.awaitingAcknowledgements;

  @override
  Widget build(BuildContext context) {
    final accent = TransferMethod.qr.accentColor;
    final state = ref.watch(senderControllerProvider);
    final notifier = ref.read(senderControllerProvider.notifier);
    final phase = state.phase;

    return GradientScaffold(
      appBar: photonAppBar(context, title: 'QR Send'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: StaggeredReveal(
            children: [
              if (state.resumableSession != null &&
                  phase == TransferPhase.idle) ...[
                GlassCard(
                  child: Column(
                    children: [
                      const Text('Resume previous transfer?'),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton(
                        onPressed: () => notifier.restoreSession(
                          state.resumableSession!,
                        ),
                        child: const Text('Resume'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (phase == TransferPhase.idle ||
                  phase == TransferPhase.preparing ||
                  phase == TransferPhase.failed) ...[
                _pickSection(state, accent, notifier),
              ] else ...[
                if (_showDisplay(phase))
                  Center(
                    child: QrFrameDisplay(data: state.currentFrameData),
                  ),
                if (_showScan(phase) && _cameraOk)
                  SizedBox(
                    height: 220,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: MobileScanner(
                            controller: _scanner,
                            onDetect: (cap) {
                              for (final b in cap.barcodes) {
                                final v = b.rawValue;
                                if (v != null) notifier.onFrameScanned(v);
                              }
                            },
                          ),
                        ),
                        const ScanFrameOverlay(
                          label: 'Scan receiver NAK/ACK QR',
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                DiagnosticsPanel(
                  diagnostics: state.diagnostics,
                  progress: state.session != null
                      ? state.diagnostics.progress
                      : 0,
                  progressLabel: 'Round ${state.roundNumber} · '
                      '${state.missingCount} missing',
                  accentColor: accent,
                  missingCount: state.missingCount,
                ),
                const SizedBox(height: AppSpacing.md),
                _actionButtons(phase, notifier, accent),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickSection(
    SenderTransferState state,
    Color accent,
    SenderController notifier,
  ) {
    return Column(
      children: [
        GlassCard(
          accentColor: accent,
          child: Text(_file?.name ?? 'No file selected'),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedPillButton(
          label: 'Choose File',
          icon: Icons.attach_file_rounded,
          color: accent,
          onPressed: () async {
            final r = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['txt', 'pdf', 'jpg', 'jpeg', 'png', 'zip'],
            );
            if (r != null && r.files.isNotEmpty) {
              setState(() => _file = r.files.first);
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedPillButton(
          label: 'Start Reliable Transfer',
          icon: Icons.qr_code_2_rounded,
          color: accent,
          onPressed: _file?.path != null
              ? () async {
                  await notifier.prepareTransfer(
                    filePath: _file!.path!,
                    fileName: _file!.name,
                    extension: _file!.extension,
                  );
                  if (ref.read(senderControllerProvider).phase !=
                      TransferPhase.failed) {
                    await notifier.startTransmission();
                  }
                }
              : null,
        ),
      ],
    );
  }

  Widget _actionButtons(
    TransferPhase phase,
    SenderController notifier,
    Color accent,
  ) {
    return Column(
      children: [
        if (phase == TransferPhase.waitingForReceiver)
          AnimatedPillButton(
            label: 'Begin Data Transfer',
            icon: Icons.play_arrow_rounded,
            color: accent,
            onPressed: notifier.beginDataTransfer,
          ),
        if (phase == TransferPhase.transmitting)
          AnimatedPillButton(
            label: 'Finish Round — Await ACK',
            icon: Icons.check_rounded,
            color: accent,
            onPressed: notifier.finishRoundAndAwaitAck,
          ),
        if (phase == TransferPhase.awaitingAcknowledgements)
          const Text(
            'Point camera at receiver status QR',
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedPillButton(
          label: 'Pause',
          icon: Icons.pause_rounded,
          color: accent,
          isOutlined: true,
          onPressed: notifier.pauseTransfer,
        ),
        AnimatedPillButton(
          label: 'Stop',
          icon: Icons.stop_rounded,
          color: Colors.red,
          isOutlined: true,
          onPressed: notifier.stopTransmission,
        ),
      ],
    );
  }
}
