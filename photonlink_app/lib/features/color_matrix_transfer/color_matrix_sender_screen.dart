import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/transfer_method.dart';
import '../../shared/components/components.dart';
import '../../shared/platform_file_utils.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/inner_screen_header.dart';
import '../../shared/widgets/transfer_info_panel.dart';
import '../../shared/widgets/transfer_presentation.dart';
import '../../shared/widgets/transfer_stage_layout.dart';
import '../../transfer/application/color_matrix_transfer_state.dart';
import '../../transfer/application/transfer_providers.dart';
import '../../ui/spacing.dart';
import 'widgets/color_matrix_frame_display.dart';

/// Color Matrix sender: pick file, show matrix preview, stream frames.
class ColorMatrixSenderScreen extends ConsumerStatefulWidget {
  const ColorMatrixSenderScreen({super.key});

  @override
  ConsumerState<ColorMatrixSenderScreen> createState() =>
      _ColorMatrixSenderScreenState();
}

class _ColorMatrixSenderScreenState
    extends ConsumerState<ColorMatrixSenderScreen> {
  PlatformFile? _selectedFile;
  bool _isPicking = false;
  String? _pickError;

  static const _method = TransferMethod.colorMatrix;

  Future<void> _pickFile() async {
    setState(() {
      _isPicking = true;
      _pickError = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'jpg', 'jpeg', 'png', 'zip'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isPicking = false);
        return;
      }

      final file = result.files.first;
      if (!isPlatformFileReady(file)) {
        setState(() {
          _pickError = 'Could not read file data';
          _isPicking = false;
        });
        return;
      }

      ref.read(colorMatrixSenderControllerProvider.notifier).reset();
      setState(() {
        _selectedFile = file;
        _isPicking = false;
      });
    } catch (e) {
      setState(() {
        _pickError = e.toString();
        _isPicking = false;
      });
    }
  }

  Future<void> _prepareAndStart() async {
    final file = _selectedFile;
    if (file == null || !isPlatformFileReady(file)) return;

    final notifier = ref.read(colorMatrixSenderControllerProvider.notifier);
    await notifier.prepareTransfer(
      fileName: file.name,
      extension: file.extension,
      filePath: platformFilePath(file),
      fileBytes: file.bytes,
    );

    final state = ref.read(colorMatrixSenderControllerProvider);
    if (state.phase == TransferPhase.failed) return;

    await notifier.startTransmission();
  }

  @override
  void dispose() {
    ref.read(colorMatrixSenderControllerProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _method.accentColor;
    final state = ref.watch(colorMatrixSenderControllerProvider);
    final isTransmitting = state.phase == TransferPhase.transmitting;

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const InnerScreenHeader(title: 'Color Matrix · Send'),
            Expanded(
              child: isTransmitting
                  ? _stageView(state, accent)
                  : _pickView(state, accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageView(ColorMatrixSenderState state, Color accent) {
    final diag = state.diagnostics;
    final progress = state.totalFrames > 0
        ? (state.currentFrameIndex + 1) / state.totalFrames
        : 0.0;

    return TransferStageLayout(
      display: ColorMatrixFrameDisplay(
        rasterBytes: state.currentColorMatrixRaster,
      ),
      info: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: TransferInfoPanel(
          accentColor: accent,
          methodName: 'Color Matrix',
          statusLabel: TransferPresentation.phaseLabel(state.phase),
          statusTone: TransferPresentation.phaseTone(state.phase),
          progress: progress,
          progressLabel:
              'Frame ${state.currentFrameIndex + 1}/${state.totalFrames} · Loop ${state.loopCount + 1}',
          fileName: state.session?.fileName ?? _selectedFile?.name,
          fileSizeLabel: _selectedFile != null
              ? TransferPresentation.formatBytes(_selectedFile!.size)
              : null,
          throughputLabel:
              TransferPresentation.formatSpeed(diag.throughputBytesPerSecond),
          qualityScore: state.qualityScore.score,
          adaptiveProfile: state.transportProfile.id,
          encryptionOn: state.encryption == EncryptionMode.enabled,
          compressionLabel: state.compression == CompressionType.none
              ? 'Off'
              : state.compression.id.toUpperCase(),
          sessionId: state.session?.id,
          extraRows: [
            PhotonInfoTile(
              label: 'Grid',
              value:
                  '${state.gridSize}×${state.gridSize} · ${state.bitsPerChannel} bpc',
              dense: true,
            ),
            PhotonInfoTile(
              label: 'Frames generated',
              value: '${diag.framesGenerated}',
              dense: true,
            ),
          ],
        ),
      ),
      controls: _Controls(
        fps: state.framesPerSecond,
        accent: accent,
        onFps: (v) => ref
            .read(colorMatrixSenderControllerProvider.notifier)
            .setFrameRate(v),
        onStop: () => ref
            .read(colorMatrixSenderControllerProvider.notifier)
            .stopTransmission(),
      ),
    );
  }

  Widget _pickView(ColorMatrixSenderState state, Color accent) {
    final theme = Theme.of(context);
    final ready = _selectedFile != null &&
        isPlatformFileReady(_selectedFile!) &&
        state.phase != TransferPhase.preparing;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              PhotonCard(
                accentColor: accent,
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.insert_drive_file_rounded
                          : Icons.grid_view_rounded,
                      size: 56,
                      color: accent,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _selectedFile?.name ?? 'No file selected',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        TransferPresentation.formatBytes(_selectedFile!.size),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_pickError != null || state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _pickError ?? state.errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PhotonButton(
                label: _isPicking ? 'Selecting…' : 'Choose File',
                icon: Icons.attach_file_rounded,
                accentColor: accent,
                loading: _isPicking,
                onPressed: _isPicking ? null : _pickFile,
              ),
              const SizedBox(height: AppSpacing.sm),
              PhotonButton(
                label: state.phase == TransferPhase.preparing
                    ? 'Preparing…'
                    : 'Start Transmission',
                icon: Icons.play_arrow_rounded,
                variant: PhotonButtonVariant.secondary,
                accentColor: accent,
                onPressed: ready ? _prepareAndStart : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.fps,
    required this.accent,
    required this.onFps,
    required this.onStop,
  });

  final double fps;
  final Color accent;
  final ValueChanged<double> onFps;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.speed_rounded, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Slider(
                value: fps.clamp(1, 10),
                min: 1,
                max: 10,
                divisions: 9,
                label: '${fps.toStringAsFixed(1)} fps',
                onChanged: onFps,
              ),
            ),
            Text(
              '${fps.toStringAsFixed(1)} fps',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        PhotonButton(
          label: 'Stop Transmission',
          icon: Icons.stop_rounded,
          variant: PhotonButtonVariant.danger,
          onPressed: onStop,
        ),
      ],
    );
  }
}
