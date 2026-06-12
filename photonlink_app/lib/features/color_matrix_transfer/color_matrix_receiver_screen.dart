import 'dart:async';

import 'package:camera/camera.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

import '../../protocols/transfer_method.dart';

import '../../settings/domain/app_settings.dart';

import '../../core/errors/app_exceptions.dart';
import '../../services/camera/camera_error_messages.dart';
import '../../services/camera/camera_platform.dart';
import '../../services/permissions/permission_service.dart';
import '../../shared/widgets/camera_error_panel.dart';

import '../../settings/application/settings_controller.dart';

import '../../shared/components/components.dart';

import '../../shared/widgets/gradient_scaffold.dart';

import '../../shared/widgets/inner_screen_header.dart';

import '../../shared/widgets/scan_frame_overlay.dart';

import '../../shared/widgets/transfer_info_panel.dart';

import '../../shared/widgets/transfer_presentation.dart';

import '../../shared/widgets/transfer_stage_layout.dart';

import '../../transfer/adaptive/brightness_sampler.dart';

import '../../transfer/application/color_matrix_receiver_controller.dart';
import '../../transfer/application/color_matrix_transfer_state.dart';
import '../../transfer/application/transfer_providers.dart';

import '../../transfer/color_matrix/color_frame_detector.dart';

import '../../transfer/color_matrix/color_matrix_frame.dart';

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

  String? _permissionError;

  String? _cameraError;

  String? _streamWarning;

  bool _streamActive = false;

  bool _isProcessing = false;

  DateTime _lastProcess = DateTime.fromMillisecondsSinceEpoch(0);

  final _detector = const ColorFrameDetector();

  ColorMatrixReceiverController? _receiverNotifier;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _receiverNotifier =
          ref.read(colorMatrixReceiverControllerProvider.notifier);
    });

    _initPermission();
  }

  Future<void> _initPermission() async {
    setState(() {
      _checkingPermission = true;
      _permissionError = null;
      _cameraError = null;
      _streamWarning = null;
    });

    try {
      await _permissionService.ensureCamera();
      if (!mounted) return;

      setState(() {
        _permissionGranted = true;
        _checkingPermission = false;
      });

      await _initCamera();
    } on PermissionDeniedException catch (e) {
      if (mounted) {
        setState(() {
          _permissionGranted = false;
          _checkingPermission = false;
          _permissionError = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _permissionGranted = false;
          _checkingPermission = false;
          _permissionError = describeCameraFailure(e);
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

      final controller = createColorMatrixCameraController(camera, preset);

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
            : describeCameraFailure(e);
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _streamActive = streamActive;
        _streamWarning = streamWarning;
        _cameraError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = describeCameraFailure(e);
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

      final rgb = cameraImageToRgb(image);

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

  @override
  void dispose() {
    _receiverNotifier?.reset();

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
                child: CameraErrorPanel(
                  message: _permissionError ??
                      'Camera permission is required for Color Matrix scanning.',
                  onRetry: _initPermission,
                  onOpenSettings: _permissionService.openSettings,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraError != null &&
        (_cameraController == null ||
            !_cameraController!.value.isInitialized)) {
      return GradientScaffold(
        body: SafeArea(
          child: Column(
            children: [
              const InnerScreenHeader(title: 'Color Matrix · Receive'),
              Expanded(
                child: CameraErrorPanel(
                  message: _cameraError!,
                  onRetry: _initPermission,
                  onOpenSettings: _permissionService.openSettings,
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
                  cameraWarning: _streamWarning,
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
