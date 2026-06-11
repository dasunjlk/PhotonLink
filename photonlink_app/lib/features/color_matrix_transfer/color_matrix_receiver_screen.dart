import 'dart:async';

import 'package:camera/camera.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

import '../../protocols/transfer_method.dart';

import '../../settings/domain/app_settings.dart';

import '../../services/permissions/permission_service.dart';

import '../../settings/application/settings_controller.dart';

import '../../shared/components/components.dart';

import '../../shared/widgets/gradient_scaffold.dart';

import '../../shared/widgets/inner_screen_header.dart';

import '../../shared/widgets/scan_frame_overlay.dart';

import '../../shared/widgets/transfer_info_panel.dart';

import '../../shared/widgets/transfer_presentation.dart';

import '../../shared/widgets/transfer_stage_layout.dart';

import '../../transfer/adaptive/brightness_sampler.dart';

import '../../transfer/application/color_matrix_transfer_state.dart';

import '../../transfer/application/transfer_providers.dart';

import '../../transfer/color_matrix/color_frame_detector.dart';

import '../../transfer/color_matrix/color_matrix_frame.dart';

import '../../ui/spacing.dart';

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

  String? _initError;

  bool _streamActive = false;

  bool _isProcessing = false;

  DateTime _lastProcess = DateTime.fromMillisecondsSinceEpoch(0);

  final _detector = const ColorFrameDetector();

  @override
  void initState() {
    super.initState();

    _initPermission();
  }

  Future<void> _initPermission() async {
    setState(() {
      _checkingPermission = true;
      _initError = null;
    });

    try {
      await _permissionService.ensureCamera();
      if (!mounted) return;

      setState(() {
        _permissionGranted = true;
        _checkingPermission = false;
      });

      await _initCamera();
    } catch (e) {
      if (mounted) {
        setState(() {
          _permissionGranted = false;
          _checkingPermission = false;
          _initError = e.toString();
        });
      }
    }
  }

  Future<void> _initCamera() async {
    final settings = ref.read(settingsProvider);

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'noCamera',
          'No camera found on this device.',
        );
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final preset = settings.cameraResolution == 'high'
          ? ResolutionPreset.high
          : ResolutionPreset.medium;

      final controller = kIsWeb
          ? CameraController(camera, preset, enableAudio: false)
          : CameraController(
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

      await ref
          .read(colorMatrixReceiverControllerProvider.notifier)
          .startReceiving(
            cameraWidth: controller.value.previewSize?.height.toInt() ?? 0,
            cameraHeight: controller.value.previewSize?.width.toInt() ?? 0,
          );

      var streamActive = false;
      String? streamWarning;
      try {
        await controller.startImageStream(_onImageStream);
        streamActive = true;
      } catch (e) {
        streamWarning = kIsWeb
            ? 'Live frame analysis is limited on web. Use the Android or desktop app for full Color Matrix receive.'
            : 'Could not start camera frame stream: $e';
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _streamActive = streamActive;
        _initError = streamWarning;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _permissionGranted = false;
          _initError = e.toString();
        });
      }
    }
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

        final uvIndex = (y ~/ 2) * image.planes[1].bytesPerRow + (x ~/ 2) * 2;

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

    if (_streamActive) {
      _cameraController?.stopImageStream();
    }

    _cameraController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _method.accentColor;

    final state = ref.watch(colorMatrixReceiverControllerProvider);

    final settings = ref.watch(settingsProvider);

    final showQuality = settings.qualityMonitoringEnabled;

    ref.listen<ColorMatrixReceiverState>(
      colorMatrixReceiverControllerProvider,
      (prev, next) {
        if (prev?.phase != TransferPhase.completed &&
            next.phase == TransferPhase.completed) {
          if (_streamActive) _cameraController?.stopImageStream();

          context.push(AppRoutes.colorMatrixComplete, extra: next);
        } else if (prev?.phase != TransferPhase.failed &&
            next.phase == TransferPhase.failed) {
          if (_streamActive) _cameraController?.stopImageStream();

          context.push(AppRoutes.colorMatrixComplete, extra: next);
        }
      },
    );

    if (_checkingPermission) {
      return const GradientScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_permissionGranted) {
      return GradientScaffold(
        body: SafeArea(
          child: Column(
            children: [
              const InnerScreenHeader(title: 'Color Matrix · Receive'),
              Expanded(
                child: _PermissionDenied(
                  message: _initError ??
                      'Camera permission is required for Color Matrix scanning.',
                  onRetry: _initPermission,
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
            const InnerScreenHeader(title: 'Color Matrix · Receive'),
            Expanded(
              child: TransferStageLayout(
                display: _CameraPane(controller: _cameraController),
                info: _buildInfo(
                  state,
                  accent,
                  settings,
                  showQuality,
                  cameraWarning: _initError,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(
    ColorMatrixReceiverState state,
    Color accent,
    AppSettings settings,
    bool showQuality, {
    String? cameraWarning,
  }) {
    final diag = state.diagnostics;

    final session = state.session;

    final progressLabel = session != null
        ? '${state.receivedChunks}/${state.totalChunks} chunks'
        : 'Waiting for color matrix…';

    final extraRows = <PhotonInfoTile>[
      PhotonInfoTile(
        label: 'Grid',
        value:
            '${state.gridSize}×${state.gridSize} · ${state.bitsPerChannel} bpc',
        dense: true,
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
      PhotonInfoTile(
        label: 'Missing',
        value: '${state.missingChunks}',
        dense: true,
      ),
      if (settings.debugOverlay)
        PhotonInfoTile(
          label: 'Detection',
          value: '${(state.detectionAccuracy * 100).toStringAsFixed(0)}%',
          dense: true,
        ),
      if (state.lighting.showOverlay && state.lighting.hint.isNotEmpty)
        PhotonInfoTile(
          label: 'Lighting',
          value: state.lighting.hint,
          icon: Icons.wb_sunny_outlined,
          dense: true,
        ),
      if (state.adaptive.mismatchWarning != null)
        PhotonInfoTile(
          label: 'Warning',
          value: state.adaptive.mismatchWarning!,
          dense: true,
        ),
      if (cameraWarning != null)
        PhotonInfoTile(
          label: 'Camera',
          value: cameraWarning,
          dense: true,
        ),
    ];

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: TransferInfoPanel(
        accentColor: accent,
        methodName: 'Color Matrix',
        statusLabel: TransferPresentation.phaseLabel(state.phase),
        statusTone: TransferPresentation.phaseTone(state.phase),
        progress: state.progress,
        progressLabel: progressLabel,
        fileName: session?.fileName,
        fileSizeLabel: session != null
            ? TransferPresentation.formatBytes(session.fileSize)
            : null,
        throughputLabel:
            TransferPresentation.formatSpeed(diag.throughputBytesPerSecond),
        qualityScore: showQuality ? state.qualityScore.score : null,
        adaptiveProfile: state.transportProfile.id,
        encryptionOn: settings.encryptionEnabled,
        compressionLabel: settings.compressionEnabled ? 'On' : 'Off',
        sessionId: session?.id,
        extraRows: extraRows,
      ),
    );
  }
}

class _CameraPane extends StatelessWidget {
  const _CameraPane({required this.controller});

  final CameraController? controller;

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller!.value.previewSize?.height ?? 1,
                height: controller!.value.previewSize?.width ?? 1,
                child: CameraPreview(controller!),
              ),
            ),
            ScanFrameOverlay(
              frameSize: constraints.biggest.shortestSide * 0.72,
              label: 'Align color matrix within frame',
            ),
          ],
        );
      },
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded, size: 64),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PhotonButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              expand: false,
              onPressed: onRetry,
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
