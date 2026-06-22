import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/camera/camera_error_messages.dart';
import '../../services/camera/camera_platform.dart';
import '../../services/camera/camera_session.dart';
import '../../services/camera/qr_image_decoder.dart';
import '../../services/logger/app_logger.dart';
import '../../services/permissions/permission_service.dart';
import 'camera_error_panel.dart';
import 'scan_frame_overlay.dart';

/// QR scanner that uses [MobileScanner] on mobile/macOS and camera capture +
/// ZXing on Windows/Linux desktop.
class PhotonQrScannerView extends StatefulWidget {
  const PhotonQrScannerView({
    required this.scanLabel,
    required this.onDetect,
    this.onError,
    this.frameSizeFactor = 0.72,
    super.key,
  });

  final String scanLabel;
  final ValueChanged<String> onDetect;
  final ValueChanged<String>? onError;
  final double frameSizeFactor;

  @override
  State<PhotonQrScannerView> createState() => _PhotonQrScannerViewState();
}

class _PhotonQrScannerViewState extends State<PhotonQrScannerView> {
  MobileScannerController? _mobileScanner;
  CameraController? _desktopCamera;
  Timer? _pollTimer;
  bool _initializing = true;
  bool _busy = false;
  String? _error;
  String? _lastPayload;

  @override
  void initState() {
    super.initState();
    if (isMobileScannerQrSupported()) {
      _mobileScanner = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
      _mobileScanner!.addListener(_onMobileScannerState);
      _initializing = false;
    } else {
      unawaited(_initDesktopScanner());
    }
  }

  void _onMobileScannerState() {
    final error = _mobileScanner?.value.error;
    if (error == null || !mounted) return;
    final message = describeMobileScannerFailure(error);
    setState(() => _error = message);
    widget.onError?.call(message);
  }

  Future<void> _initDesktopScanner() async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    try {
      final controller = await openPreferredCamera(
        preset: ResolutionPreset.high,
        permissionService: PermissionService(),
      );
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _desktopCamera = controller;
        _initializing = false;
      });

      _pollTimer = Timer.periodic(
        const Duration(milliseconds: 350),
        (_) => unawaited(_pollDesktopFrame()),
      );
    } catch (e) {
      if (!mounted) return;
      final message = describeCameraFailure(e);
      setState(() {
        _error = message;
        _initializing = false;
      });
      widget.onError?.call(message);
    }
  }

  Future<void> _pollDesktopFrame() async {
    final controller = _desktopCamera;
    if (_busy || controller == null || !controller.value.isInitialized) {
      AppLogger.debug('[QR Scanner] Skipping poll (busy=$_busy, controller=$controller)');
      return;
    }
    _busy = true;
    try {
      final sw = Stopwatch()..start();
      final capture = await controller.takePicture();
      final bytes = await File(capture.path).readAsBytes();
      final payload = decodeQrFromImageBytes(bytes);
      sw.stop();
      if (payload == null) {
        AppLogger.warning('[QR Scanner] No QR found in frame (${sw.elapsedMilliseconds}ms)');
        return;
      }
      if (payload == _lastPayload) {
        AppLogger.debug('[QR Scanner] Duplicate payload, skipping');
        return;
      }
      _lastPayload = payload;
      AppLogger.info('[QR Scanner] QR decoded (${payload.length} chars, ${sw.elapsedMilliseconds}ms)');
      widget.onDetect(payload);
    } catch (e) {
      AppLogger.warning('[QR Scanner] Capture error: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> _retry() async {
    if (isMobileScannerQrSupported()) {
      setState(() => _error = null);
      await _mobileScanner?.start();
      return;
    }
    await _desktopCamera?.dispose();
    _desktopCamera = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    await _initDesktopScanner();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mobileScanner?.removeListener(_onMobileScannerState);
    _mobileScanner?.dispose();
    _desktopCamera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return CameraErrorPanel(
        message: _error!,
        onRetry: _retry,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final frameSize = constraints.biggest.shortestSide * widget.frameSizeFactor;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (isMobileScannerQrSupported() && _mobileScanner != null)
              MobileScanner(
                controller: _mobileScanner!,
                errorBuilder: (context, error) {
                  final message = describeMobileScannerFailure(error);
                  widget.onError?.call(message);
                  return CameraErrorPanel(
                    message: message,
                    onRetry: () => _mobileScanner?.start(),
                  );
                },
                onDetect: (capture) {
                  for (final barcode in capture.barcodes) {
                    final value = barcode.rawValue;
                    if (value != null) widget.onDetect(value);
                  }
                },
              )
            else if (_desktopCamera != null)
              buildCameraPreview(_desktopCamera!),
            ScanFrameOverlay(
              frameSize: frameSize,
              label: widget.scanLabel,
            ),
          ],
        );
      },
    );
  }
}
