import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../history/domain/transfer_record.dart';
import '../../ui/radii.dart';
import '../../ui/spacing.dart';
import 'photon_card.dart';
import 'photon_status_badge.dart';

/// A history list row rendering a single [TransferRecord].
///
/// Shows file name, transfer method, direction, file size, date, time,
/// transfer duration, and a success/failed badge. When failed, the failure
/// reason is shown inline.
class PhotonHistoryCard extends StatelessWidget {
  const PhotonHistoryCard({
    required this.record,
    super.key,
    this.onTap,
  });

  final TransferRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.onSurface;
    final dateFmt = DateFormat.yMMMd();
    final timeFmt = DateFormat.jm();

    return PhotonCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      semanticLabel:
          '${record.fileName}, ${record.method.displayName}, ${record.status.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: AppRadii.mdRadius,
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Icon(record.method.icon, color: accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.fileName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${record.method.displayName}  ·  ${record.direction.label}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _statusBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _meta(theme, Icons.sd_storage_rounded,
                  _formatSize(record.sizeBytes),),
              _meta(theme, Icons.calendar_today_rounded,
                  dateFmt.format(record.timestamp),),
              _meta(theme, Icons.schedule_rounded,
                  timeFmt.format(record.timestamp),),
              _meta(theme, Icons.timer_outlined,
                  _formatDuration(record.durationMs),),
            ],
          ),
          if (record.status == TransferStatus.failed &&
              record.failureReason != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: AppRadii.smRadius,
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.report_problem_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      record.failureReason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge() {
    final (tone, label, icon) = switch (record.status) {
      TransferStatus.success => (
          PhotonStatusTone.success,
          'Success',
          Icons.check_circle_rounded
        ),
      TransferStatus.failed => (
          PhotonStatusTone.error,
          'Failed',
          Icons.error_rounded
        ),
      TransferStatus.cancelled => (
          PhotonStatusTone.warning,
          'Cancelled',
          Icons.cancel_rounded
        ),
      TransferStatus.inProgress => (
          PhotonStatusTone.info,
          'In Progress',
          Icons.sync_rounded
        ),
    };
    return PhotonStatusBadge(
        label: label, tone: tone, icon: icon, compact: true,);
  }

  Widget _meta(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String _formatDuration(int ms) {
    if (ms <= 0) return '—';
    if (ms < 1000) return '${ms}ms';
    final seconds = ms / 1000;
    if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
    final minutes = seconds ~/ 60;
    final rem = (seconds % 60).round();
    return '${minutes}m ${rem}s';
  }
}
