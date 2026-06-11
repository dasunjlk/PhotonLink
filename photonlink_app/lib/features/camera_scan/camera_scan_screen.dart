import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/errors/app_exceptions.dart';
import '../../protocols/transfer_method.dart';
import '../../services/permissions/permission_service.dart';
import '../../shared/components/components.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/inner_screen_header.dart';
import '../../shared/widgets/scan_frame_overlay.dart';
import '../../ui/spacing.dart';

/// Camera preview prototype with scan framing overlay. No decoding yet.
class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({
    required this.method,
    super.key,
  });

  final TransferMethod method;

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  CameraController? _controller;
  String? _errorMessage;
  bool _isInitializing = true;

  final _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      await _permissionService.ensureCamera();
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw const CameraUnavailableException(
            'No cameras found on this device.',);
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } on PhotonLinkException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: _isInitializing || _errorMessage != null
            ? Column(
                children: [
                  InnerScreenHeader(
                      title: 'Scan · ${widget.method.displayName}',),
                  Expanded(child: _buildBody()),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  _buildBody(),
                  InnerScreenHeader(
                      title: 'Scan · ${widget.method.displayName}',),
                ],
              ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Initializing camera…'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _ErrorView(
        message: _errorMessage!,
        onRetry: () {
          setState(() {
            _errorMessage = null;
            _isInitializing = true;
          });
          _initCamera();
        },
        onOpenSettings: _permissionService.openSettings,
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: Text('Camera not available'));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        ScanFrameOverlay(
          label: 'Align ${widget.method.displayName} signal within frame',
        ),
        Positioned(
          bottom: AppSpacing.xxl,
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          child: Text(
            'Phase 1 prototype — live preview only, no decoding',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              PhotonButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
              const SizedBox(height: AppSpacing.sm),
              PhotonButton(
                label: 'Open Settings',
                variant: PhotonButtonVariant.ghost,
                onPressed: onOpenSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
