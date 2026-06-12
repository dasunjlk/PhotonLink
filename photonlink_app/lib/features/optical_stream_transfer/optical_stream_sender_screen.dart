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
import '../../transfer/application/optical_stream_sender_controller.dart';
import '../../transfer/application/optical_stream_transfer_state.dart';
import '../../transfer/application/transfer_providers.dart';
import '../../ui/spacing.dart';
import 'widgets/optical_stream_frame_display.dart';
import 'widgets/stream_diagnostics_panel.dart';

/// Optical Stream sender: pick file, show live stream visualization.
class OpticalStreamSenderScreen extends ConsumerStatefulWidget {
  const OpticalStreamSenderScreen({super.key});

  @override
  ConsumerState<OpticalStreamSenderScreen> createState() =>
      _OpticalStreamSenderScreenState();
}

class _OpticalStreamSenderScreenState
    extends ConsumerState<OpticalStreamSenderScreen> {
  PlatformFile? _selectedFile;
  bool _isPicking = false;
  String? _pickError;
  OpticalStreamSenderController? _senderNotifier;

  static const _method = TransferMethod.opticalStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _senderNotifier =
          ref.read(opticalStreamSenderControllerProvider.notifier);
    });
  }

  @override
  void dispose() {
    _senderNotifier?.reset();
    super.dispose();
  }

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
      ref.read(opticalStreamSenderControllerProvider.notifier).reset();
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
    final notifier = ref.read(opticalStreamSenderControllerProvider.notifier);
    await notifier.prepareTransfer(
      fileName: file.name,
      extension: file.extension,
      filePath: platformFilePath(file),
      fileBytes: file.bytes,
    );
    final state = ref.read(opticalStreamSenderControllerProvider);
    if (state.phase == TransferPhase.failed) return;
    await notifier.startTransmission();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _method.accentColor;
    final state = ref.watch(opticalStreamSenderControllerProvider);
    final isTransmitting = state.phase == TransferPhase.transmitting;

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const InnerScreenHeader(title: 'Optical Stream · Send'),
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

  Widget _stageView(OpticalStreamSenderState state, Color accent) {
    final diag = state.diagnostics;
    final progress = state.totalFrames > 0
        ? (state.currentFrameIndex + 1) / state.totalFrames
        : 0.0;

    return TransferStageLayout(
      display: OpticalStreamFrameDisplay(
        rasterBytes: state.currentOpticalRaster,
      ),
      info: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            TransferInfoPanel(
              accentColor: accent,
              methodName: 'Optical Stream',
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
            ),
            const SizedBox(height: AppSpacing.sm),
            StreamDiagnosticsPanel(
              frameRate: state.frameRate,
              throughputBytesPerSec: state.throughputBytesPerSec,
              recoveredPackets: 0,
              recoveryRate: 0,
              droppedFrames: 0,
              qualityScore: state.qualityScore,
              syncLocked: state.syncLocked,
            ),
          ],
        ),
      ),
      controls: _Controls(
        fps: state.framesPerSecond,
        accent: accent,
        onFps: (v) => ref
            .read(opticalStreamSenderControllerProvider.notifier)
            .setFrameRate(v),
        onStop: () => ref
            .read(opticalStreamSenderControllerProvider.notifier)
            .stopTransmission(),
      ),
    );
  }

  Widget _pickView(OpticalStreamSenderState state, Color accent) {
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
                          : Icons.videocam_rounded,
                      size: 56,
                      color: accent,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _selectedFile?.name ?? 'No file selected',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (_pickError != null || state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _pickError ?? state.errorMessage!,
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
                    : 'Start Stream',
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
                value: fps.clamp(2, 15),
                min: 2,
                max: 15,
                divisions: 13,
                label: '${fps.toStringAsFixed(1)} fps',
                onChanged: onFps,
              ),
            ),
            Text('${fps.toStringAsFixed(1)} fps'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        PhotonButton(
          label: 'Stop Stream',
          icon: Icons.stop_rounded,
          variant: PhotonButtonVariant.danger,
          onPressed: onStop,
        ),
      ],
    );
  }
}
