import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

import '../../protocols/interfaces/compression_type.dart';

import '../../protocols/interfaces/encryption_mode.dart';

import '../../protocols/transfer_method.dart';

import '../../shared/components/components.dart';

import '../../shared/platform_file_utils.dart';

import '../../services/permissions/permission_service.dart';

import '../../shared/widgets/gradient_scaffold.dart';

import '../../shared/widgets/inner_screen_header.dart';

import '../../shared/widgets/scan_frame_overlay.dart';

import '../../shared/widgets/transfer_info_panel.dart';

import '../../shared/widgets/transfer_presentation.dart';

import '../../shared/widgets/transfer_stage_layout.dart';

import '../../transfer/application/sender_controller.dart';

import '../../transfer/application/transfer_providers.dart';

import '../../transfer/application/transfer_state.dart';

import '../../ui/spacing.dart';

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

    final isPickPhase = phase == TransferPhase.idle ||
        phase == TransferPhase.preparing ||
        phase == TransferPhase.failed;

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const InnerScreenHeader(title: 'QR Transfer · Send'),
            Expanded(
              child: isPickPhase
                  ? _PickView(
                      file: _file,
                      accent: accent,
                      state: state,
                      onChoose: _chooseFile,
                      onStart: () => _startTransfer(notifier),
                    )
                  : _stageView(state, notifier, accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageView(
    SenderTransferState state,
    SenderController notifier,
    Color accent,
  ) {
    final phase = state.phase;

    final diag = state.diagnostics;

    final progress = state.session != null ? diag.progress : 0.0;

    return TransferStageLayout(
      display: _DisplayPane(
        showDisplay: _showDisplay(phase),
        showScan: _showScan(phase) && _cameraOk,
        frameData: state.currentFrameData,
        scanner: _scanner,
        scanLabel: 'Scan receiver NAK/ACK QR',
        onDetect: notifier.onFrameScanned,
      ),
      info: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: TransferInfoPanel(
          accentColor: accent,
          methodName: 'QR Transfer',
          statusLabel: TransferPresentation.phaseLabel(phase),
          statusTone: TransferPresentation.phaseTone(phase),
          progress: progress,
          progressLabel:
              'Round ${state.roundNumber} · ${state.missingCount} missing',
          fileName: _file?.name,
          fileSizeLabel: _file != null
              ? TransferPresentation.formatBytes(_file!.size)
              : null,
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
              label: 'Packets sent',
              value: '${diag.packetsSent}',
              dense: true,
            ),
            PhotonInfoTile(
              label: 'ACK / NAK',
              value: '${diag.ackCount} / ${diag.nakCount}',
              dense: true,
            ),
            PhotonInfoTile(
              label: 'Retries',
              value: '${diag.retries}',
              dense: true,
            ),
          ],
        ),
      ),
      controls: _Controls(phase: phase, notifier: notifier, accent: accent),
      banner: state.resumableSession != null && phase == TransferPhase.idle
          ? _ResumeBanner(
              onResume: () => notifier.restoreSession(state.resumableSession!),
            )
          : null,
    );
  }

  Future<void> _chooseFile() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf', 'jpg', 'jpeg', 'png', 'zip'],
      withData: true,
    );

    if (r != null && r.files.isNotEmpty) {
      setState(() => _file = r.files.first);
    }
  }

  Future<void> _startTransfer(SenderController notifier) async {
    final file = _file;

    if (file == null || !isPlatformFileReady(file)) return;

    await notifier.prepareTransfer(
      fileName: file.name,
      extension: file.extension,
      filePath: platformFilePath(file),
      fileBytes: file.bytes,
    );

    if (ref.read(senderControllerProvider).phase != TransferPhase.failed) {
      await notifier.startTransmission();
    }
  }
}

class _PickView extends StatelessWidget {
  const _PickView({
    required this.file,
    required this.accent,
    required this.state,
    required this.onChoose,
    required this.onStart,
  });

  final PlatformFile? file;

  final Color accent;

  final SenderTransferState state;

  final VoidCallback onChoose;

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ready = file != null && isPlatformFileReady(file!);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhotonCard(
                accentColor: accent,
                child: Column(
                  children: [
                    Icon(
                      file != null
                          ? Icons.insert_drive_file_rounded
                          : Icons.upload_file_rounded,
                      size: 56,
                      color: accent,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      file?.name ?? 'No file selected',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (file != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        TransferPresentation.formatBytes(file!.size),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PhotonButton(
                label: 'Choose File',
                icon: Icons.attach_file_rounded,
                accentColor: accent,
                onPressed: onChoose,
              ),
              const SizedBox(height: AppSpacing.sm),
              PhotonButton(
                label: 'Start Reliable Transfer',
                icon: Icons.qr_code_2_rounded,
                variant: PhotonButtonVariant.secondary,
                accentColor: accent,
                onPressed: ready ? onStart : null,
              ),
            ],
          ),
        ),
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
    required this.scanLabel,
    required this.onDetect,
  });

  final bool showDisplay;

  final bool showScan;

  final String? frameData;

  final MobileScannerController scanner;

  final String scanLabel;

  final ValueChanged<String> onDetect;

  @override
  Widget build(BuildContext context) {
    if (showDisplay && showScan) {
      return Column(
        children: [
          Expanded(
            flex: 3,
            child: QrFrameDisplay(data: frameData),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: _ScanPane(
              scanner: scanner,
              scanLabel: scanLabel,
              onDetect: onDetect,
            ),
          ),
        ],
      );
    }

    if (showDisplay) {
      return QrFrameDisplay(data: frameData);
    }

    if (showScan) {
      return _ScanPane(
        scanner: scanner,
        scanLabel: scanLabel,
        onDetect: onDetect,
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}

class _ScanPane extends StatelessWidget {
  const _ScanPane({
    required this.scanner,
    required this.scanLabel,
    required this.onDetect,
  });

  final MobileScannerController scanner;

  final String scanLabel;

  final ValueChanged<String> onDetect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: scanner,
              onDetect: (cap) {
                for (final b in cap.barcodes) {
                  final v = b.rawValue;

                  if (v != null) onDetect(v);
                }
              },
            ),
            ScanFrameOverlay(
              frameSize: constraints.biggest.shortestSide * 0.65,
              label: scanLabel,
            ),
          ],
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.phase,
    required this.notifier,
    required this.accent,
  });

  final TransferPhase phase;

  final SenderController notifier;

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (phase == TransferPhase.waitingForReceiver)
          PhotonButton(
            label: 'Begin Data Transfer',
            icon: Icons.play_arrow_rounded,
            accentColor: accent,
            onPressed: notifier.beginDataTransfer,
          ),
        if (phase == TransferPhase.transmitting)
          PhotonButton(
            label: 'Finish Round — Await ACK',
            icon: Icons.check_rounded,
            accentColor: accent,
            onPressed: notifier.finishRoundAndAwaitAck,
          ),
        if (phase == TransferPhase.awaitingAcknowledgements)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Point camera at receiver status QR',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (phase == TransferPhase.waitingForReceiver ||
            phase == TransferPhase.transmitting ||
            phase == TransferPhase.awaitingAcknowledgements)
          const SizedBox(height: AppSpacing.sm),
        PhotonButton(
          label: 'Pause',
          icon: Icons.pause_rounded,
          variant: PhotonButtonVariant.secondary,
          accentColor: accent,
          onPressed: notifier.pauseTransfer,
        ),
        const SizedBox(height: AppSpacing.sm),
        PhotonButton(
          label: 'Stop',
          icon: Icons.stop_rounded,
          variant: PhotonButtonVariant.danger,
          onPressed: notifier.stopTransmission,
        ),
      ],
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return PhotonCard(
      child: Row(
        children: [
          const Icon(Icons.restore_rounded),
          const SizedBox(width: AppSpacing.md),
          const Expanded(child: Text('Resume previous transfer?')),
          PhotonButton(
            label: 'Resume',
            expand: false,
            onPressed: onResume,
          ),
        ],
      ),
    );
  }
}
