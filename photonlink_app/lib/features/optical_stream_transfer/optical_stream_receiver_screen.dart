import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/router/app_router.dart';
import '../../protocols/transfer_method.dart';
import '../../services/camera/camera_error_messages.dart';
import '../../services/camera/camera_platform.dart';
import '../../services/permissions/permission_service.dart';
import '../../settings/application/settings_controller.dart';
import '../../shared/components/components.dart';
import '../../shared/widgets/camera_error_panel.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/inner_screen_header.dart';
import '../../shared/widgets/scan_frame_overlay.dart';
import '../../shared/widgets/transfer_info_panel.dart';
import '../../shared/widgets/transfer_presentation.dart';
import '../../shared/widgets/transfer_stage_layout.dart';
import '../../transfer/adaptive/brightness_sampler.dart';
import '../../transfer/application/optical_stream_receiver_controller.dart';
import '../../transfer/application/optical_stream_transfer_state.dart';
import '../../transfer/application/transfer_providers.dart';
import '../../transfer/optical_stream/optical_detector.dart';
import '../../transfer/optical_stream/optical_stream_frame.dart';
import '../../ui/spacing.dart';
import 'widgets/stream_diagnostics_panel.dart';

/// Optical Stream receiver with continuous camera frame analysis.
class OpticalStreamReceiverScreen extends ConsumerStatefulWidget {
  const OpticalStreamReceiverScreen({super.key});

  @override
  ConsumerState<OpticalStreamReceiverScreen> createState() =>
      _OpticalStreamReceiverScreenState();
}

class _OpticalStreamReceiverScreenState
    extends ConsumerState<OpticalStreamReceiverScreen> {
  static const _method = TransferMethod.opticalStream;

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
  final _detector = const OpticalDetector();
  OpticalStreamReceiverController? _receiverNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _receiverNotifier =
          ref.read(opticalStreamReceiverControllerProvider.notifier);
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
        throw CameraException('noCamera', 'No camera found on this device.');
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
          .read(opticalStreamReceiverControllerProvider.notifier)
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
            ? 'Live stream analysis is limited on web.'
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
    final notifier = ref.read(opticalStreamReceiverControllerProvider.notifier);
    final receiverState = ref.read(opticalStreamReceiverControllerProvider);
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
        notifier.onOpticalStreamFrame(
          OpticalStreamFrame(
            protocolVersion: OpticalStreamFrame.currentProtocolVersion,
            sessionId: '',
            streamId: 0,
            frameId: 0,
            packetId: 0,
            packetType: OpticalStreamPacketType.data,
            totalPackets: 0,
            payload: Uint8List(0),
            checksum: 0,
            syncMarker: 0,
            timestamp: 0,
            gridSize: gridSize,
            cells: const [],
          ),
          detectionAccuracy: 0,
          detected: false,
        );
        return;
      }
      final frame = OpticalStreamFrame(
        protocolVersion: OpticalStreamFrame.currentProtocolVersion,
        sessionId: '',
        streamId: 0,
        frameId: 0,
        packetId: 0,
        packetType: OpticalStreamPacketType.data,
        totalPackets: 0,
        payload: Uint8List(0),
        checksum: 0,
        syncMarker: 0,
        timestamp: 0,
        gridSize: detection.gridSize,
        cells: detection.cells,
      );
      notifier.onOpticalStreamFrame(
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
    final state = ref.watch(opticalStreamReceiverControllerProvider);

    ref.listen<OpticalStreamReceiverState>(
      opticalStreamReceiverControllerProvider,
      (prev, next) {
        if (prev?.phase != TransferPhase.completed &&
            next.phase == TransferPhase.completed) {
          if (_streamActive) _cameraController?.stopImageStream();
          context.push(AppRoutes.opticalStreamComplete, extra: next);
        } else if (prev?.phase != TransferPhase.failed &&
            next.phase == TransferPhase.failed) {
          if (_streamActive) _cameraController?.stopImageStream();
          context.push(AppRoutes.opticalStreamComplete, extra: next);
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
              const InnerScreenHeader(title: 'Optical Stream · Receive'),
              Expanded(
                child: CameraErrorPanel(
                  message: _permissionError ??
                      'Camera permission is required for optical scanning.',
                  onRetry: _initPermission,
                  onOpenSettings: _permissionService.openSettings,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraError != null) {
      return GradientScaffold(
        body: SafeArea(
          child: Column(
            children: [
              const InnerScreenHeader(title: 'Optical Stream · Receive'),
              Expanded(
                child: CameraErrorPanel(
                  message: _cameraError!,
                  onRetry: _initCamera,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final preview = _cameraController;
    if (preview == null || !preview.value.isInitialized) {
      return const GradientScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const InnerScreenHeader(title: 'Optical Stream · Receive'),
            Expanded(
              child: TransferStageLayout(
                display: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CameraPreview(preview),
                    ),
                    const ScanFrameOverlay(),
                  ],
                ),
                info: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      TransferInfoPanel(
                        accentColor: accent,
                        methodName: 'Optical Stream',
                        statusLabel:
                            TransferPresentation.phaseLabel(state.phase),
                        statusTone:
                            TransferPresentation.phaseTone(state.phase),
                        progress: state.progress,
                        progressLabel: state.totalChunks > 0
                            ? '${state.receivedChunks}/${state.totalChunks} chunks'
                            : 'Waiting for stream…',
                        fileName: state.session?.fileName,
                        throughputLabel: TransferPresentation.formatSpeed(
                          state.diagnostics.throughputBytesPerSecond,
                        ),
                        qualityScore: state.qualityScore.score,
                        adaptiveProfile: state.transportProfile.id,
                        sessionId: state.session?.id,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      StreamDiagnosticsPanel(
                        frameRate: state.frameRate,
                        throughputBytesPerSec: state.throughputBytesPerSec,
                        recoveredPackets: state.recoveredPackets,
                        recoveryRate: state.recoveryRate,
                        droppedFrames: state.droppedFrames,
                        qualityScore: state.qualityScore,
                        syncLocked: state.syncLocked,
                        resyncCount: state.resyncCount,
                      ),
                      if (_streamWarning != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        PhotonCard(
                          child: Text(
                            _streamWarning!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                controls: PhotonButton(
                  label: 'Reset',
                  icon: Icons.refresh_rounded,
                  variant: PhotonButtonVariant.ghost,
                  onPressed: () => ref
                      .read(opticalStreamReceiverControllerProvider.notifier)
                      .reset(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
