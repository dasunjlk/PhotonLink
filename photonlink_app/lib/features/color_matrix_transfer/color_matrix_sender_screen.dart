import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../protocols/transfer_method.dart';
import '../../shared/widgets/animated_pill_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/staggered_reveal.dart';
import '../../transfer/application/transfer_providers.dart';
import '../../transfer/application/transfer_state.dart';
import '../../ui/spacing.dart';
import '../qr_transfer/widgets/transfer_progress_bar.dart';
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
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isPicking = false);
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        setState(() {
          _pickError = 'Could not access file path';
          _isPicking = false;
        });
        return;
      }

      ref.read(senderControllerProvider(_method).notifier).reset();
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
    if (file?.path == null) return;

    final notifier = ref.read(senderControllerProvider(_method).notifier);
    await notifier.prepareTransfer(
      filePath: file!.path!,
      fileName: file.name,
      extension: file.extension,
    );

    final state = ref.read(senderControllerProvider(_method));
    if (state.phase == TransferPhase.failed) return;

    await notifier.startTransmission();
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return 'Unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    ref.read(senderControllerProvider(_method).notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _method.accentColor;
    final senderState = ref.watch(senderControllerProvider(_method));
    final isTransmitting = senderState.phase == TransferPhase.transmitting;
    final isPreparing = senderState.phase == TransferPhase.preparing;
    final session = senderState.session;
    final diag = senderState.diagnostics;

    return GradientScaffold(
      appBar: photonAppBar(context, title: 'Color Matrix Send'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: StaggeredReveal(
            children: [
              if (isTransmitting) ...[
                Center(
                  child: ColorMatrixFrameDisplay(
                    rasterBytes: senderState.currentColorMatrixRaster,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TransferProgressBar(
                  progress: senderState.totalFrames > 0
                      ? (senderState.currentFrameIndex + 1) /
                          senderState.totalFrames
                      : 0,
                  label:
                      'Frame ${senderState.currentFrameIndex + 1} / ${senderState.totalFrames} · Loop ${senderState.loopCount + 1}',
                  accentColor: accent,
                ),
                const SizedBox(height: AppSpacing.sm),
                _statsCard(theme, diag, senderState),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.speed_rounded, size: 20),
                    Expanded(
                      child: Slider(
                        value: senderState.framesPerSecond,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label:
                            '${senderState.framesPerSecond.toStringAsFixed(1)} fps',
                        onChanged: (v) => ref
                            .read(senderControllerProvider(_method).notifier)
                            .setFrameRate(v),
                      ),
                    ),
                    Text(
                      '${senderState.framesPerSecond.toStringAsFixed(1)} fps',
                    ),
                  ],
                ),
                AnimatedPillButton(
                  label: 'Stop Transmission',
                  icon: Icons.stop_rounded,
                  color: theme.colorScheme.error,
                  onPressed: () {
                    ref
                        .read(senderControllerProvider(_method).notifier)
                        .stopTransmission();
                  },
                ),
              ] else ...[
                GlassCard(
                  accentColor: accent,
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null
                            ? Icons.insert_drive_file_rounded
                            : Icons.folder_open_rounded,
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
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _formatSize(_selectedFile!.size),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_pickError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _pickError!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (senderState.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    senderState.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (session != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Session Details',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.sm),
                        _detailRow('Session ID', session.id),
                        _detailRow('Chunks', '${session.totalChunks}'),
                        _detailRow(
                          'SHA-256',
                          '${session.sha256.substring(0, 16)}…',
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sectionGap),
                AnimatedPillButton(
                  label: _isPicking ? 'Selecting…' : 'Choose File',
                  icon: Icons.attach_file_rounded,
                  color: accent,
                  onPressed: _isPicking ? null : _pickFile,
                ),
                const SizedBox(height: AppSpacing.md),
                AnimatedPillButton(
                  label: isPreparing
                      ? 'Preparing…'
                      : 'Start Color Matrix Transmission',
                  icon: Icons.grid_view_rounded,
                  color: accent,
                  isOutlined: true,
                  onPressed: _selectedFile?.path != null && !isPreparing
                      ? _prepareAndStart
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsCard(
    ThemeData theme,
    dynamic diag,
    SenderTransferState senderState,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Frame Statistics', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _detailRow('Generated', '${diag.framesGenerated}'),
          _detailRow('FPS', senderState.framesPerSecond.toStringAsFixed(1)),
          _detailRow('Loops', '${senderState.loopCount + 1}'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
