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
import '../../transfer/adaptive/brightness_sampler.dart';
import '../../transfer/application/color_matrix_transfer_state.dart';
import '../../transfer/application/transfer_providers.dart';
import '../../transfer/color_matrix/color_frame_detector.dart';
import '../../transfer/color_matrix/color_matrix_frame.dart';
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
  final _brightnessSampler = const BrightnessSampler();
  bool _permissionGranted = false;
  bool _checkingPermission = true;
  bool _isProcessing = false;
  DateTime _lastProcess = DateTime.fromMillisecondsSinceEpoch(0);

  final _detector = const ColorFrameDetector();

  @override
  void initState() {
    super.initState();
    _initPermission();
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

    await ref.read(colorMatrixReceiverControllerProvider.notifier).startReceiving(
          cameraWidth: controller.value.previewSize?.height.toInt() ?? 0,
          cameraHeight: controller.value.previewSize?.width.toInt() ?? 0,
        );

    await controller.startImageStream(_onImageStream);
  }

  Future<void> _onImageStream(CameraImage image) async {
    if (_isProcessing) return;
    final notifier = ref.read(colorMatrixReceiverControllerProvider.notifier);
    final receiverState = ref.read(colorMatrixReceiverControllerProvider);
    if (receiverState.phase == TransferPhase.completed ||
        receiverState.phase == TransferPhase.failed ||
        receiverState.phase == TransferPhase.reconstructing) {
      return;
    }

    final throttleMs = notifier.processingThrottleMs;
    final now = DateTime.now();
    if (now.difference(_lastProcess).inMilliseconds < throttleMs) return;
    _lastProcess = now;
    _isProcessing = true;

    try {
      final brightness = _brightnessSampler.sampleFromYuv(image);
      notifier.recordBrightnessSample(
        brightness.avg,
        variance: brightness.variance,
      );

      final rgb = _yuvToRgb(image);
      final gridSize = receiverState.gridSize;
      final detection = _detector.detectFromRgb(
        rgbBytes: rgb.bytes,
        width: rgb.width,
        height: rgb.height,
        gridSize: gridSize,
      );

      if (!detection.detected || detection.cells.isEmpty) {
        notifier.onColorMatrixFrame(
          ColorMatrixFrame(
            protocolVersion: ColorMatrixFrame.currentProtocolVersion,
            sessionId: '',
            frameId: 0,
            packetId: 0,
            packetType: ColorMatrixPacketType.data,
            totalPackets: 0,
            payload: Uint8List(0),
            checksum: 0,
            gridSize: gridSize,
            cells: const [],
          ),
          detectionAccuracy: 0,
          detected: false,
        );
        return;
      }

      final frame = ColorMatrixFrame(
        protocolVersion: ColorMatrixFrame.currentProtocolVersion,
        sessionId: '',
        frameId: 0,
        packetId: 0,
        packetType: ColorMatrixPacketType.data,
        totalPackets: 0,
        payload: Uint8List(0),
        checksum: 0,
        gridSize: detection.gridSize,
        cells: detection.cells,
      );

      notifier.onColorMatrixFrame(
        frame,
        detectionAccuracy: detection.accuracy,
        detected: true,
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
    ref.read(colorMatrixReceiverControllerProvider.notifier).reset();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _method.accentColor;
    final receiverState = ref.watch(colorMatrixReceiverControllerProvider);
    final settings = ref.watch(settingsProvider);
    final showQuality = settings.qualityMonitoringEnabled;

    ref.listen<ColorMatrixReceiverState>(
      colorMatrixReceiverControllerProvider,
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
                    if (receiverState.lighting.showOverlay)
                      Positioned(
                        top: 72,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.wb_sunny_outlined,
                                  color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  receiverState.lighting.hint,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (settings.debugOverlay)
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
                    if (showQuality)
                      Positioned(
                        top: 120,
                        right: 16,
                        child: _QualityBadge(
                          score: receiverState.qualityScore.score,
                          profile: receiverState.transportProfile.id,
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
                        showQuality: showQuality,
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.score, required this.profile});

  final double score;
  final String profile;

  @override
  Widget build(BuildContext context) {
    final color = score >= 75
        ? Colors.green
        : score >= 50
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        'Q ${score.toStringAsFixed(0)} · $profile',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.receiverState,
    required this.accent,
    required this.theme,
    required this.showQuality,
  });

  final ColorMatrixReceiverState receiverState;
  final Color accent;
  final ThemeData theme;
  final bool showQuality;

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
          if (showQuality)
            Text(
              'Quality: ${receiverState.qualityScore.score.toStringAsFixed(0)} · '
              '${receiverState.mappedGridLabel} · '
              '${diag.throughputBytesPerSecond.toStringAsFixed(0)} B/s',
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

extension on ColorMatrixReceiverState {
  String get mappedGridLabel => '$gridSize×$gridSize · $bitsPerChannel bpc';
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
