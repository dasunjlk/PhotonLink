import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/errors/app_exceptions.dart';
import '../../protocols/transfer_method.dart';
import '../../shared/widgets/animated_pill_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/staggered_reveal.dart';
import '../../ui/spacing.dart';

/// Local file picker prototype — selects files but does not transfer yet.
class FilePickerScreen extends StatefulWidget {
  const FilePickerScreen({
    required this.method,
    super.key,
  });

  final TransferMethod method;

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  PlatformFile? _selectedFile;
  String? _errorMessage;
  bool _isPicking = false;

  Future<void> _pickFile() async {
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isPicking = false);
        return;
      }

      setState(() {
        _selectedFile = result.files.first;
        _isPicking = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = FilePickerException('Failed to pick file: $e').message;
        _isPicking = false;
      });
    }
  }

  void _showPhase2Dialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.construction_rounded),
        title: const Text('Coming in Phase 2'),
        content: const Text(
          'File transmission will be implemented in Phase 2 when '
          'optical encoding protocols are ready.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = _selectedFile;

    return GradientScaffold(
      appBar: photonAppBar(
        context,
        title: 'Send — ${widget.method.displayName}',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: StaggeredReveal(
            children: [
              GlassCard(
                accentColor: widget.method.accentColor,
                child: Column(
                  children: [
                    Icon(
                      file != null
                          ? Icons.insert_drive_file_rounded
                          : Icons.folder_open_rounded,
                      size: 64,
                      color: widget.method.accentColor,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      file?.name ?? 'No file selected',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (file != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _formatSize(file.size),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (file.extension != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Type: .${file.extension}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (file.path != null && !Platform.isWindows) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          file.path!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.sectionGap),
              AnimatedPillButton(
                label: _isPicking ? 'Selecting…' : 'Choose File',
                icon: Icons.attach_file_rounded,
                color: widget.method.accentColor,
                onPressed: _isPicking ? null : _pickFile,
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedPillButton(
                label: 'Prepare Transmission',
                icon: Icons.send_rounded,
                color: widget.method.accentColor,
                isOutlined: true,
                onPressed: file != null ? _showPhase2Dialog : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
