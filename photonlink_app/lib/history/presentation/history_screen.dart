import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../protocols/transfer_method.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/section_header.dart';
import '../../ui/spacing.dart';
import '../application/history_controller.dart';
import '../domain/transfer_record.dart';

/// Transfer history screen with mock data and method filtering.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final filter = ref.watch(historyFilterProvider);
    final controller = ref.read(historyProvider.notifier);

    return GradientScaffold(
      appBar: photonAppBar(context, title: 'History'),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                0,
              ),
              child: const SectionHeader(
                title: 'Transfer History',
                subtitle: 'Persistent transfer log with diagnostics',
              ),
            ),
            _FilterChips(
              selected: filter,
              onSelected: (method) =>
                  ref.read(historyFilterProvider.notifier).state = method,
            ),
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (records) {
                  final filtered = controller.filtered(filter);
                  if (filtered.isEmpty) {
                    return const _EmptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      return _HistoryTile(record: filtered[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onSelected,
  });

  final TransferMethod? selected;
  final ValueChanged<TransferMethod?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          for (final method in TransferMethod.homeMethods) ...[
            FilterChip(
              avatar: Icon(method.icon, size: 16),
              label: Text(method.displayName),
              selected: selected == method,
              onSelected: (_) => onSelected(method),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final TransferRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.yMMMd().add_jm();

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      accentColor: record.method.accentColor,
      onTap: () => _showDetail(context, record),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: record.method.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              record.method.icon,
              color: record.method.accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.fileName,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.method.displayName} · ${_formatSize(record.sizeBytes)} · ${record.direction.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  timeFormat.format(record.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(status: record.status),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, TransferRecord record) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(record.fileName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session: ${record.sessionId ?? '—'}'),
            Text('Method: ${record.method.displayName}'),
            Text('Protocol v${record.protocolVersion}'),
            Text('Status: ${record.status.label}'),
            Text('Retries: ${record.retryCount}'),
            Text('Duration: ${record.durationMs} ms'),
            Text('Compression: ${record.compressionUsed ? 'Yes' : 'No'}'),
            Text('Encryption: ${record.encryptionUsed ? 'Yes' : 'No'}'),
            if (record.compressionRatio != null)
              Text(
                'Compression ratio: ${record.compressionRatio!.toStringAsFixed(2)}',
              ),
            if (record.transferSpeedBytesPerSec != null)
              Text(
                'Speed: ${record.transferSpeedBytesPerSec!.toStringAsFixed(0)} B/s',
              ),
            if (record.failureReason != null)
              Text('Failure: ${record.failureReason}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final TransferStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      TransferStatus.success => (Colors.green, Icons.check_circle_rounded),
      TransferStatus.failed => (Colors.red, Icons.error_rounded),
      TransferStatus.cancelled => (Colors.orange, Icons.cancel_rounded),
      TransferStatus.inProgress => (Colors.blue, Icons.sync_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No transfers found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
