import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/router/app_router.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/transfer_method.dart';
import '../../services/camera/camera_error_messages.dart';
import '../../services/camera/camera_platform.dart';
import '../../services/permissions/permission_service.dart';
import '../../shared/components/components.dart';
import '../../shared/widgets/camera_error_panel.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/inner_screen_header.dart';
import '../../shared/widgets/scan_frame_overlay.dart';
import '../../shared/widgets/transfer_info_panel.dart';
import '../../shared/widgets/transfer_presentation.dart';
import '../../shared/widgets/transfer_stage_layout.dart';
import '../../transfer/application/receiver_controller.dart';
import '../../transfer/application/transfer_providers.dart';
import '../../transfer/application/transfer_state.dart';
import '../../ui/spacing.dart';
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
  String? _cameraError;

  ReceiverController? _receiverNotifier;

  @override
  void initState() {
    super.initState();
    _scanner.addListener(_onScannerStateChanged);
    _init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _receiverNotifier = ref.read(receiverControllerProvider.notifier);
      _receiverNotifier!.startReceiving();
      _receiverNotifier!.checkResumableSession();
    });
  }

  void _onScannerStateChanged() {
    final error = _scanner.value.error;
    if (error == null || !mounted) return;

    setState(() {
      _cameraOk = false;
      _cameraError = describeMobileScannerFailure(error);
    });
  }

  Future<void> _init() async {
    setState(() {
      _checking = true;
      _cameraError = null;
    });

    if (!isQrCameraScanSupported()) {
      if (mounted) {
        setState(() {
          _cameraOk = false;
          _checking = false;
          _cameraError =
              'QR camera scanning is not supported on Windows or Linux. Use the web or mobile app.';
        });
      }
      return;
    }

    try {
      await _permission.ensureCamera();
      if (mounted) {
        setState(() {
          _cameraOk = true;
          _checking = false;
        });
      }
    } on PermissionDeniedException catch (e) {
      if (mounted) {
        setState(() {
          _cameraOk = false;
          _checking = false;
          _cameraError = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraOk = false;
          _checking = false;
          _cameraError = describeCameraFailure(e);
        });
      }
    }
  }

  @override
  void dispose() {
    _scanner.removeListener(_onScannerStateChanged);
    _receiverNotifier?.reset();
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

    ref.listen<ReceiverTransferState>(receiverControllerProvider, (p, n) {
      if (p?.phase != TransferPhase.completed &&
          n.phase == TransferPhase.completed) {
        context.push(AppRoutes.qrComplete, extra: n);
      } else if (p?.phase != TransferPhase.failed &&
          n.phase == TransferPhase.failed) {
        context.push(AppRoutes.qrComplete, extra: n);
      }
    });

    if (_checking) {
      return const GradientScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_cameraOk) {
      return GradientScaffold(
        body: SafeArea(
          child: Column(
            children: [
              const InnerScreenHeader(title: 'QR Transfer · Receive'),
              Expanded(
                child: CameraErrorPanel(
                  message: _cameraError ??
                      'Camera access is required to scan sender QR frames.',
                  onRetry: _init,
                  onOpenSettings: _permission.openSettings,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const InnerScreenHeader(title: 'QR Transfer · Receive'),
            Expanded(
              child: TransferStageLayout(
                display: _DisplayPane(
                  showDisplay: _showDisplay(state.phase),
                  showScan: _showScan(state.phase),
                  frameData: state.currentFrameData,
                  scanner: _scanner,
                  onDetect: notifier.onFrameScanned,
                  onScannerError: (error) {
                    if (!mounted) return;
                    setState(() {
                      _cameraOk = false;
                      _cameraError = describeMobileScannerFailure(error);
                    });
                  },
                ),
                info: _buildInfo(state, accent),
                controls: _buildControls(state, notifier, accent),
                banner: _resumeBanner(state, notifier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(ReceiverTransferState state, Color accent) {
    final diag = state.diagnostics;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: TransferInfoPanel(
        accentColor: accent,
        methodName: 'QR Transfer',
        statusLabel: TransferPresentation.phaseLabel(state.phase),
        statusTone: TransferPresentation.phaseTone(state.phase),
        progress: state.progress,
        progressLabel: '${state.receivedChunks}/${state.totalChunks} chunks',
        fileName: state.session?.fileName,
        throughputLabel: TransferPresentation.formatSpeed(
          diag.transferSpeedBytesPerSec > 0
              ? diag.transferSpeedBytesPerSec
              : diag.throughputBytesPerSec,
        ),
        encryptionOn: state.encryption == EncryptionMode.enabled,
        compressionLabel: state.compression == CompressionType.none
            ? 'Off'
            : state.compression.id.toUpperCase(),
        sessionId: state.session?.id,
        extraRows: [
          PhotonInfoTile(
            label: 'Missing',
            value: '${state.missingCount}',
            dense: true,
          ),
          PhotonInfoTile(
            label: 'Packets received',
            value: '${diag.packetsReceived}',
            dense: true,
          ),
          if (state.statusMessage != null)
            PhotonInfoTile(
              label: 'Status',
              value: state.statusMessage!,
              dense: true,
            ),
        ],
      ),
    );
  }

  Widget _buildControls(
    ReceiverTransferState state,
    ReceiverController notifier,
    Color accent,
  ) {
    final phase = state.phase;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (phase == TransferPhase.receiving)
          PhotonButton(
            label: 'Show NAK/ACK to Sender',
            icon: Icons.qr_code_rounded,
            accentColor: accent,
            onPressed: notifier.showStatusToSender,
          ),
        if (phase == TransferPhase.waitingForReceiver) ...[
          PhotonButton(
            label: 'Show Handshake (Resume)',
            icon: Icons.handshake_rounded,
            variant: PhotonButtonVariant.secondary,
            accentColor: accent,
            onPressed: notifier.showHandshakeToSender,
          ),
        ],
        if (phase == TransferPhase.receiving ||
            phase == TransferPhase.waitingForReceiver)
          const SizedBox(height: AppSpacing.sm),
        PhotonButton(
          label: 'Pause',
          icon: Icons.pause_rounded,
          variant: PhotonButtonVariant.secondary,
          accentColor: accent,
          onPressed: notifier.pauseTransfer,
        ),
      ],
    );
  }

  Widget? _resumeBanner(
    ReceiverTransferState state,
    ReceiverController notifier,
  ) {
    if (state.resumableSession == null ||
        state.phase != TransferPhase.waitingForReceiver) {
      return null;
    }
    return PhotonCard(
      child: Row(
        children: [
          const Icon(Icons.restore_rounded),
          const SizedBox(width: AppSpacing.md),
          const Expanded(child: Text('Resume session?')),
          PhotonButton(
            label: 'Resume',
            expand: false,
            onPressed: () => notifier.restoreSession(state.resumableSession!),
          ),
        ],
      ),
    );
  }
}

class _DisplayPane extends StatelessWidget {
  const _DisplayPane({
    required this.showDisplay,
    required this.showScan,
    required this.frameData,
    required this.scanner,
    required this.onDetect,
    required this.onScannerError,
  });

  final bool showDisplay;
  final bool showScan;
  final String? frameData;
  final MobileScannerController scanner;
  final ValueChanged<String> onDetect;
  final ValueChanged<MobileScannerException> onScannerError;

  @override
  Widget build(BuildContext context) {
    if (showDisplay) {
      return QrFrameDisplay(data: frameData);
    }

    if (showScan) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: scanner,
                errorBuilder: (context, error) {
                  onScannerError(error);
                  return CameraErrorPanel(
                    message: describeMobileScannerFailure(error),
                    onRetry: () => scanner.start(),
                  );
                },
                onDetect: (cap) {
                  for (final b in cap.barcodes) {
                    final v = b.rawValue;
                    if (v != null) onDetect(v);
                  }
                },
              ),
              ScanFrameOverlay(
                frameSize: constraints.biggest.shortestSide * 0.72,
                label: 'Scan sender QR frames',
              ),
            ],
          );
        },
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}
