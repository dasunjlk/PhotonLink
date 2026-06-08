import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../protocols/transfer_method.dart';
import '../../services/permissions/permission_service.dart';
import '../../settings/application/settings_controller.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/scan_frame_overlay.dart';
import '../../transfer/application/transfer_providers.dart';
import '../../transfer/application/transfer_state.dart';
import '../../transfer/color_matrix/color_frame_detector.dart';
import '../../transfer/color_matrix/color_matrix_frame.dart';
import '../../transfer/color_matrix/color_matrix_frame_codec.dart';
import '../../ui/spacing.dart';
import '../qr_transfer/widgets/transfer_progress_bar.dart';

/// Color Matrix receiver with live camera frame analysis.
class ColorMatrixReceiverScreen extends ConsumerStatefulWidget {
  const ColorMatrixReceiverScreen({super.key});

  @override
  ConsumerState<ColorMatrixReceiverScreen> createState() =>
      _ColorMatrixReceiverScreenState();
}

class _ColorMatrixReceiverScreenState
    extends ConsumerState<ColorMatrixReceiverScreen> {
  static const _method = TransferMethod.colorMatrix;

  CameraController? _cameraController;
  final _permissionService = PermissionService();
  bool _permissionGranted = false;
  bool _checkingPermission = true;
  bool _isProcessing = false;
  DateTime _lastProcess = DateTime.fromMillisecondsSinceEpoch(0);
  static const _throttleMs = 200;

  final _detector = const ColorFrameDetector();
  @override
  void initState() {
    super.initState();
    _initPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receiverControllerProvider(_method).notifier).startReceiving();
    });
  }

  Future<void> _initPermission() async {
    try {
      await _permissionService.ensureCamera();
      if (!mounted) return;
      setState(() {
        _permissionGranted = true;
        _checkingPermission = false;
      });
      await _initCamera();
    } catch (_) {
      if (mounted) {
        setState(() {
          _permissionGranted = false;
          _checkingPermission = false;
        });
      }
    }
  }

  Future<void> _initCamera() async {
    final settings = ref.read(settingsProvider);
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final preset = settings.cameraResolution == 'high'
        ? ResolutionPreset.high
        : ResolutionPreset.medium;

    final controller = CameraController(
      camera,
      preset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() => _cameraController = controller);

    await controller.startImageStream(_onImageStream);
  }

  Future<void> _onImageStream(CameraImage image) async {
    if (_isProcessing) return;
    final receiverState = ref.read(receiverControllerProvider(_method));
    if (receiverState.phase == TransferPhase.completed ||
        receiverState.phase == TransferPhase.failed ||
        receiverState.phase == TransferPhase.reconstructing) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastProcess).inMilliseconds < _throttleMs) return;
    _lastProcess = now;
    _isProcessing = true;

    try {
      final rgb = _yuvToRgb(image);
      final settings = ref.read(settingsProvider);
      final detection = _detector.detectFromRgb(
        rgbBytes: rgb.bytes,
        width: rgb.width,
        height: rgb.height,
        gridSize: settings.colorMatrixSize,
      );

      if (!detection.detected || detection.cells.isEmpty) return;

      final frame = ColorMatrixFrame(
        protocolVersion: ColorMatrixFrame.currentProtocolVersion,
        sessionId: '',
        frameId: 0,
        packetId: 0,
        isMetadata: false,
        totalPackets: 0,
        payload: Uint8List(0),
        checksum: 0,
        gridSize: detection.gridSize,
        cells: detection.cells,
      );

      ref.read(receiverControllerProvider(_method).notifier).onColorMatrixFrame(
            frame,
            detectionAccuracy: detection.accuracy,
          );
    } catch (_) {
      // Skip bad frames
    } finally {
      _isProcessing = false;
    }
  }

  _RgbBuffer _yuvToRgb(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes.length > 1 ? image.planes[1].bytes : yPlane;
    final vPlane = image.planes.length > 2 ? image.planes[2].bytes : yPlane;

    final rgb = Uint8List(width * height * 3);
    var idx = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yIndex = y * image.planes[0].bytesPerRow + x;
        final uvIndex =
            (y ~/ 2) * image.planes[1].bytesPerRow + (x ~/ 2) * 2;

        final yVal = yPlane[yIndex];
        final uVal = uPlane[uvIndex];
        final vVal = vPlane[uvIndex.clamp(0, vPlane.length - 1)];

        var r = yVal + 1.402 * (vVal - 128);
        var g = yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128);
        var b = yVal + 1.772 * (uVal - 128);

        rgb[idx++] = r.round().clamp(0, 255);
        rgb[idx++] = g.round().clamp(0, 255);
        rgb[idx++] = b.round().clamp(0, 255);
      }
    }

    return _RgbBuffer(rgb, width, height);
  }

  @override
  void dispose() {
    ref.read(receiverControllerProvider(_method).notifier).reset();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _method.accentColor;
    final receiverState = ref.watch(receiverControllerProvider(_method));

    ref.listen<ReceiverTransferState>(
      receiverControllerProvider(_method),
      (prev, next) {
        if (prev?.phase != TransferPhase.completed &&
            next.phase == TransferPhase.completed) {
          _cameraController?.stopImageStream();
          context.push(AppRoutes.colorMatrixComplete, extra: next);
        } else if (prev?.phase != TransferPhase.failed &&
            next.phase == TransferPhase.failed) {
          _cameraController?.stopImageStream();
          context.push(AppRoutes.colorMatrixComplete, extra: next);
        }
      },
    );

    return GradientScaffold(
      appBar: photonAppBar(context, title: 'Color Matrix Receive'),
      body: _checkingPermission
          ? const Center(child: CircularProgressIndicator())
          : !_permissionGranted
              ? _PermissionDenied(onRetry: _initPermission)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_cameraController != null &&
                        _cameraController!.value.isInitialized)
                      CameraPreview(_cameraController!)
                    else
                      const Center(child: CircularProgressIndicator()),
                    ScanFrameOverlay(
                      label: 'Align color matrix within frame',
                    ),
                    if (ref.watch(settingsProvider).debugOverlay)
                      Positioned(
                        top: 80,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.black54,
                          child: Text(
                            'Detection: ${(receiverState.detectionAccuracy * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    Positioned(
                      left: AppSpacing.screenPadding,
                      right: AppSpacing.screenPadding,
                      bottom: AppSpacing.xxl,
                      child: _ProgressPanel(
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

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.receiverState,
    required this.accent,
    required this.theme,
  });

  final ReceiverTransferState receiverState;
  final Color accent;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final session = receiverState.session;
    final diag = receiverState.diagnostics;
    final label = session != null
        ? '${receiverState.receivedChunks} / ${receiverState.totalChunks} chunks'
        : 'Waiting for color matrix…';

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
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Frames: ${diag.framesReceived} · Corrupted: ${diag.framesCorrupted} · Missing: ${receiverState.missingChunks}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          if (receiverState.duplicatesIgnored > 0)
            Text(
              'Duplicates: ${receiverState.duplicatesIgnored}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
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
              'Camera permission is required for Color Matrix scanning.',
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

class _RgbBuffer {
  const _RgbBuffer(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width;
  final int height;
}
