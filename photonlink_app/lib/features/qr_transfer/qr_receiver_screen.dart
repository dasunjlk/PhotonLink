import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/router/app_router.dart';
import '../../protocols/transfer_method.dart';
import '../../services/permissions/permission_service.dart';
import '../../shared/widgets/animated_pill_button.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/scan_frame_overlay.dart';
import '../../transfer/application/transfer_providers.dart';
import '../../transfer/application/transfer_state.dart';
import '../../ui/spacing.dart';
import 'widgets/diagnostics_panel.dart';
import 'widgets/qr_frame_display.dart';

/// Bidirectional QR receiver: scan + display status QR.
class QrReceiverScreen extends ConsumerStatefulWidget {
  const QrReceiverScreen({super.key});

  @override
  ConsumerState<QrReceiverScreen> createState() => _QrReceiverScreenState();
}

class _QrReceiverScreenState extends ConsumerState<QrReceiverScreen> {
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final _permission = PermissionService();
  bool _cameraOk = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receiverControllerProvider.notifier).startReceiving();
      ref.read(receiverControllerProvider.notifier).checkResumableSession();
    });
  }

  Future<void> _init() async {
    try {
      await _permission.ensureCamera();
      if (mounted) setState(() { _cameraOk = true; _checking = false; });
    } catch (_) {
      if (mounted) setState(() { _cameraOk = false; _checking = false; });
    }
  }

  @override
  void dispose() {
    ref.read(receiverControllerProvider.notifier).reset();
    _scanner.dispose();
    super.dispose();
  }

  bool _showDisplay(TransferPhase phase) =>
      phase == TransferPhase.awaitingAcknowledgements ||
      phase == TransferPhase.recoveringMissingPackets ||
      phase == TransferPhase.completed;

  bool _showScan(TransferPhase phase) =>
      phase == TransferPhase.waitingForReceiver ||
      phase == TransferPhase.receiving ||
      phase == TransferPhase.resuming;

  @override
  Widget build(BuildContext context) {
    final accent = TransferMethod.qr.accentColor;
    final state = ref.watch(receiverControllerProvider);
    final notifier = ref.read(receiverControllerProvider.notifier);
    final phase = state.phase;

    ref.listen<ReceiverTransferState>(receiverControllerProvider, (p, n) {
      if (p?.phase != TransferPhase.completed &&
          n.phase == TransferPhase.completed) {
        context.push(AppRoutes.qrComplete, extra: n);
      } else if (p?.phase != TransferPhase.failed && n.phase == TransferPhase.failed) {
        context.push(AppRoutes.qrComplete, extra: n);
      }
    });

    if (_checking) {
      return const GradientScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GradientScaffold(
      appBar: photonAppBar(context, title: 'QR Receive'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_showScan(phase) && _cameraOk)
            MobileScanner(
              controller: _scanner,
              onDetect: (cap) {
                for (final b in cap.barcodes) {
                  final v = b.rawValue;
                  if (v != null) notifier.onFrameScanned(v);
                }
              },
            ),
          if (_showDisplay(phase))
            Center(
              child: QrFrameDisplay(data: state.currentFrameData),
            ),
          if (_showScan(phase))
            const ScanFrameOverlay(label: 'Scan sender QR frames'),
          Positioned(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            bottom: AppSpacing.lg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.resumableSession != null &&
                    phase == TransferPhase.waitingForReceiver)
                  Card(
                    child: ListTile(
                      title: const Text('Resume session?'),
                      trailing: TextButton(
                        onPressed: () => notifier.restoreSession(
                          state.resumableSession!,
                        ),
                        child: const Text('Resume'),
                      ),
                    ),
                  ),
                DiagnosticsPanel(
                  diagnostics: state.diagnostics,
                  progress: state.progress,
                  progressLabel:
                      '${state.receivedChunks}/${state.totalChunks} chunks',
                  accentColor: accent,
                  missingCount: state.missingCount,
                  compression: state.compression,
                  encryption: state.encryption,
                  compressionSavingsBytes: state.compressionSavingsBytes,
                ),
                if (state.statusMessage != null)
                  Text(
                    state.statusMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                const SizedBox(height: AppSpacing.sm),
                if (phase == TransferPhase.receiving)
                  AnimatedPillButton(
                    label: 'Show NAK/ACK to Sender',
                    icon: Icons.qr_code_rounded,
                    color: accent,
                    onPressed: notifier.showStatusToSender,
                  ),
                if (phase == TransferPhase.waitingForReceiver)
                  AnimatedPillButton(
                    label: 'Show Handshake (Resume)',
                    icon: Icons.handshake_rounded,
                    color: accent,
                    isOutlined: true,
                    onPressed: notifier.showHandshakeToSender,
                  ),
                AnimatedPillButton(
                  label: 'Pause',
                  icon: Icons.pause_rounded,
                  color: accent,
                  isOutlined: true,
                  onPressed: notifier.pauseTransfer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
