import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/router/app_router.dart';
import '../../protocols/transfer_method.dart';
import '../../services/permissions/permission_service.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/scan_frame_overlay.dart';
import '../../transfer/application/transfer_providers.dart';
import '../../transfer/application/transfer_state.dart';
import '../../ui/spacing.dart';
import 'widgets/transfer_progress_bar.dart';

/// QR receiver: continuous scan, decode packets, show progress.
class QrReceiverScreen extends ConsumerStatefulWidget {
  const QrReceiverScreen({super.key});

  @override
  ConsumerState<QrReceiverScreen> createState() => _QrReceiverScreenState();
}

class _QrReceiverScreenState extends ConsumerState<QrReceiverScreen> {
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final _permissionService = PermissionService();
  bool _permissionGranted = false;
  bool _checkingPermission = true;
  DateTime _lastScan = DateTime.fromMillisecondsSinceEpoch(0);
  static const _scanThrottleMs = 50;

  @override
  void initState() {
    super.initState();
    _initPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receiverControllerProvider.notifier).startReceiving();
    });
  }

  Future<void> _initPermission() async {
    try {
      await _permissionService.ensureCamera();
      if (mounted) {
        setState(() {
          _permissionGranted = true;
          _checkingPermission = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _permissionGranted = false;
          _checkingPermission = false;
        });
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final receiverState = ref.read(receiverControllerProvider);
    if (receiverState.phase == TransferPhase.completed ||
        receiverState.phase == TransferPhase.failed ||
        receiverState.phase == TransferPhase.reconstructing) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastScan).inMilliseconds < _scanThrottleMs) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;
      _lastScan = now;
      ref.read(receiverControllerProvider.notifier).onFrameScanned(raw);
      break;
    }

  }

  @override
  void dispose() {
    ref.read(receiverControllerProvider.notifier).reset();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = TransferMethod.qr.accentColor;
    final receiverState = ref.watch(receiverControllerProvider);

    ref.listen<ReceiverTransferState>(receiverControllerProvider, (prev, next) {
      if (prev?.phase != TransferPhase.completed &&
          next.phase == TransferPhase.completed) {
        _scannerController.stop();
        context.push(AppRoutes.qrComplete, extra: next);
      } else if (prev?.phase != TransferPhase.failed &&
          next.phase == TransferPhase.failed) {
        _scannerController.stop();
        context.push(AppRoutes.qrComplete, extra: next);
      }
    });

    return GradientScaffold(
      appBar: photonAppBar(context, title: 'QR Receive'),
      body: _checkingPermission
          ? const Center(child: CircularProgressIndicator())
          : !_permissionGranted
              ? _PermissionDenied(onRetry: _initPermission)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                    ),
                    ScanFrameOverlay(
                      label: 'Align QR code within frame',
                    ),
                    Positioned(
                      left: AppSpacing.screenPadding,
                      right: AppSpacing.screenPadding,
                      bottom: AppSpacing.xxl,
                      child: GlassProgressPanel(
                        receiverState: receiverState,
                        accent: accent,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
    );
  }
}

class GlassProgressPanel extends StatelessWidget {
  const GlassProgressPanel({
    required this.receiverState,
    required this.accent,
    required this.theme,
    super.key,
  });

  final ReceiverTransferState receiverState;
  final Color accent;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final session = receiverState.session;
    final label = session != null
        ? '${receiverState.receivedChunks} / ${receiverState.totalChunks} chunks'
        : 'Waiting for session QR…';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (session != null) ...[
            Text(
              session.fileName,
              style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          TransferProgressBar(
            progress: receiverState.progress,
            label: label,
            accentColor: accent,
          ),
          if (receiverState.duplicatesIgnored > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Duplicates ignored: ${receiverState.duplicatesIgnored}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
          if (receiverState.phase == TransferPhase.reconstructing)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded, size: 64),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Camera permission is required to scan QR codes.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
