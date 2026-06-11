import 'package:flutter/material.dart';

import '../../features/qr_transfer/widgets/transfer_progress_bar.dart';
import '../../ui/spacing.dart';
import '../components/components.dart';

/// The right-hand information panel for the Transfer (send / receive) screen.
///
/// Presents file, transport, live-progress, reliability, and session data
/// sourced entirely from existing controllers — this widget is presentation
/// only and performs no transfer logic.
class TransferInfoPanel extends StatelessWidget {
  const TransferInfoPanel({
    required this.methodName,
    required this.statusLabel,
    required this.statusTone,
    required this.progress,
    required this.progressLabel,
    super.key,
    this.accentColor,
    this.fileName,
    this.fileSizeLabel,
    this.throughputLabel,
    this.qualityScore,
    this.fecLabel,
    this.adaptiveProfile,
    this.encryptionOn = false,
    this.compressionLabel = 'Off',
    this.sessionId,
    this.extraRows = const [],
    this.title = 'Transfer Details',
  });

  final String methodName;
  final String statusLabel;
  final PhotonStatusTone statusTone;
  final double progress;
  final String progressLabel;
  final Color? accentColor;
  final String? fileName;
  final String? fileSizeLabel;
  final String? throughputLabel;
  final double? qualityScore;
  final String? fecLabel;
  final String? adaptiveProfile;
  final bool encryptionOn;
  final String compressionLabel;
  final String? sessionId;
  final List<PhotonInfoTile> extraRows;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PhotonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
              PhotonStatusBadge(
                  label: statusLabel, tone: statusTone, compact: true,),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TransferProgressBar(
            progress: progress,
            label: progressLabel,
            accentColor: accentColor,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          if (fileName != null)
            PhotonInfoTile(
              label: 'File',
              value: fileName!,
              icon: Icons.insert_drive_file_rounded,
              dense: true,
            ),
          if (fileSizeLabel != null)
            PhotonInfoTile(
              label: 'Size',
              value: fileSizeLabel!,
              icon: Icons.sd_storage_rounded,
              dense: true,
            ),
          PhotonInfoTile(
            label: 'Method',
            value: methodName,
            icon: Icons.swap_horiz_rounded,
            dense: true,
          ),
          if (throughputLabel != null)
            PhotonInfoTile(
              label: 'Throughput',
              value: throughputLabel!,
              icon: Icons.speed_rounded,
              dense: true,
            ),
          if (qualityScore != null)
            PhotonInfoTile(
              label: 'Quality Score',
              icon: Icons.auto_graph_rounded,
              dense: true,
              valueWidget: PhotonStatusBadge(
                label: qualityScore!.toStringAsFixed(0),
                tone: qualityScore! >= 75
                    ? PhotonStatusTone.success
                    : qualityScore! >= 50
                        ? PhotonStatusTone.warning
                        : PhotonStatusTone.error,
                compact: true,
              ),
            ),
          if (adaptiveProfile != null)
            PhotonInfoTile(
              label: 'Adaptive Profile',
              value: adaptiveProfile!,
              icon: Icons.tune_rounded,
              dense: true,
            ),
          if (fecLabel != null)
            PhotonInfoTile(
              label: 'FEC',
              value: fecLabel!,
              icon: Icons.shield_moon_rounded,
              dense: true,
            ),
          PhotonInfoTile(
            label: 'Encryption',
            icon: Icons.lock_rounded,
            dense: true,
            valueWidget: PhotonStatusBadge(
              label: encryptionOn ? 'On' : 'Off',
              tone: encryptionOn
                  ? PhotonStatusTone.success
                  : PhotonStatusTone.neutral,
              compact: true,
            ),
          ),
          PhotonInfoTile(
            label: 'Compression',
            value: compressionLabel,
            icon: Icons.compress_rounded,
            dense: true,
          ),
          if (sessionId != null && sessionId!.isNotEmpty)
            PhotonInfoTile(
              label: 'Session',
              value: sessionId!,
              icon: Icons.fingerprint_rounded,
              dense: true,
            ),
          ...extraRows,
        ],
      ),
    );
  }
}
