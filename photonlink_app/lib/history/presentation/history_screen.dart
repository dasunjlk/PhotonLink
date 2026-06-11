import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../protocols/transfer_method.dart';
import '../../shared/components/components.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/inner_screen_header.dart';
import '../../ui/radii.dart';
import '../../ui/responsive.dart';
import '../../ui/spacing.dart';
import '../application/history_controller.dart';
import '../domain/transfer_record.dart';

/// Transfer history screen with search, method, and status filtering.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  TransferMethod? _methodFilter;
  TransferStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransferRecord> _applyFilters(List<TransferRecord> records) {
    final q = _query.trim().toLowerCase();
    return records.where((r) {
      if (_methodFilter != null && r.method != _methodFilter) return false;
      if (_statusFilter != null && r.status != _statusFilter) return false;
      if (q.isNotEmpty && !r.fileName.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  bool get _hasActiveFilters => _methodFilter != null || _statusFilter != null;

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _FilterSheet(
        method: _methodFilter,
        status: _statusFilter,
        onApply: (m, s) {
          setState(() {
            _methodFilter = m;
            _statusFilter = s;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InnerScreenHeader(
              title: 'Transfer History',
              actions: [
                PhotonIconButton(
                  icon: _hasActiveFilters
                      ? Icons.filter_alt_rounded
                      : Icons.filter_alt_outlined,
                  tooltip: 'Filters',
                  accentColor: _hasActiveFilters
                      ? Theme.of(context).colorScheme.onSurface
                      : null,
                  onPressed: _openFilters,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.xs,
                AppSpacing.screenPadding,
                AppSpacing.sm,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by file name',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            if (_hasActiveFilters)
              _ActiveFilterRow(
                method: _methodFilter,
                status: _statusFilter,
                onClear: () => setState(() {
                  _methodFilter = null;
                  _statusFilter = null;
                }),
              ),
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (records) {
                  final filtered = _applyFilters(records);
                  if (filtered.isEmpty) {
                    return _EmptyState(
                      hasRecords: records.isNotEmpty,
                    );
                  }
                  return _HistoryList(records: filtered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.records});

  final List<TransferRecord> records;

  @override
  Widget build(BuildContext context) {
    final twoColumn = context.isDesktop;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: twoColumn
              ? _TwoColumn(records: records)
              : Column(
                  children: [
                    for (final r in records) ...[
                      PhotonHistoryCard(
                        record: r,
                        onTap: () => _showDetail(context, r),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.records});

  final List<TransferRecord> records;

  @override
  Widget build(BuildContext context) {
    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < records.length; i++) {
      final card = Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: PhotonHistoryCard(
          record: records[i],
          onTap: () => _showDetail(context, records[i]),
        ),
      );
      (i.isEven ? left : right).add(card);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(children: right)),
      ],
    );
  }
}

void _showDetail(BuildContext context, TransferRecord record) {
  final timeFormat = DateFormat.yMMMd().add_jm();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title:
          Text(record.fileName, maxLines: 2, overflow: TextOverflow.ellipsis),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhotonInfoTile(
                label: 'Method', value: record.method.displayName, dense: true,),
            PhotonInfoTile(
                label: 'Direction', value: record.direction.label, dense: true,),
            PhotonInfoTile(
                label: 'Status', value: record.status.label, dense: true,),
            PhotonInfoTile(
                label: 'Date',
                value: timeFormat.format(record.timestamp),
                dense: true,),
            PhotonInfoTile(
                label: 'Duration',
                value: '${record.durationMs} ms',
                dense: true,),
            PhotonInfoTile(
                label: 'Retries', value: '${record.retryCount}', dense: true,),
            PhotonInfoTile(
              label: 'Compression',
              value: record.compressionUsed ? 'Yes' : 'No',
              dense: true,
            ),
            PhotonInfoTile(
              label: 'Encryption',
              value: record.encryptionUsed ? 'Yes' : 'No',
              dense: true,
            ),
            if (record.compressionRatio != null)
              PhotonInfoTile(
                label: 'Compression ratio',
                value: record.compressionRatio!.toStringAsFixed(2),
                dense: true,
              ),
            if (record.transferSpeedBytesPerSec != null)
              PhotonInfoTile(
                label: 'Speed',
                value:
                    '${record.transferSpeedBytesPerSec!.toStringAsFixed(0)} B/s',
                dense: true,
              ),
            if (record.profileUsed != null)
              PhotonInfoTile(
                  label: 'Profile', value: record.profileUsed!, dense: true,),
            if (record.sessionId != null)
              PhotonInfoTile(
                  label: 'Session', value: record.sessionId!, dense: true,),
            if (record.failureReason != null)
              PhotonInfoTile(
                  label: 'Failure', value: record.failureReason!, dense: true,),
            if (record.fecProfile != null)
              PhotonInfoTile(
                  label: 'FEC profile', value: record.fecProfile!, dense: true,),
            if (record.packetsRecovered > 0)
              PhotonInfoTile(
                label: 'Packets recovered',
                value: '${record.packetsRecovered}',
                dense: true,
              ),
            if (record.recoveryRate != null)
              PhotonInfoTile(
                label: 'Recovery rate',
                value:
                    '${(record.recoveryRate! * 100).toStringAsFixed(1)}%',
                dense: true,
              ),
            if (record.parityOverhead != null)
              PhotonInfoTile(
                label: 'Parity overhead',
                value: record.parityOverhead!.toStringAsFixed(2),
                dense: true,
              ),
          ],
        ),
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

class _ActiveFilterRow extends StatelessWidget {
  const _ActiveFilterRow({
    required this.method,
    required this.status,
    required this.onClear,
  });

  final TransferMethod? method;
  final TransferStatus? status;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (method != null)
            PhotonStatusBadge(
              label: method!.displayName,
              tone: PhotonStatusTone.info,
              icon: method!.icon,
              compact: true,
            ),
          if (status != null)
            PhotonStatusBadge(
              label: status!.label,
              tone: PhotonStatusTone.info,
              icon: Icons.flag_rounded,
              compact: true,
            ),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_all_rounded, size: 16),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.method,
    required this.status,
    required this.onApply,
  });

  final TransferMethod? method;
  final TransferStatus? status;
  final void Function(TransferMethod?, TransferStatus?) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TransferMethod? _method = widget.method;
  late TransferStatus? _status = widget.status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Text('Method', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _method == null,
                onSelected: (_) => setState(() => _method = null),
              ),
              for (final m in TransferMethod.homeMethods)
                ChoiceChip(
                  avatar: Icon(m.icon, size: 16),
                  label: Text(m.displayName),
                  selected: _method == m,
                  onSelected: (_) => setState(() => _method = m),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Status', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _status == null,
                onSelected: (_) => setState(() => _status = null),
              ),
              for (final s in TransferStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: PhotonButton(
                  label: 'Reset',
                  variant: PhotonButtonVariant.secondary,
                  onPressed: () => setState(() {
                    _method = null;
                    _status = null;
                  }),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PhotonButton(
                  label: 'Apply',
                  onPressed: () {
                    widget.onApply(_method, _status);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasRecords});

  final bool hasRecords;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: AppRadii.xlRadius,
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Icon(
                hasRecords ? Icons.search_off_rounded : Icons.history_rounded,
                size: 44,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              hasRecords ? 'No matching transfers' : 'No transfers yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasRecords
                  ? 'Try adjusting your search or filters.'
                  : 'Completed transfers will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
