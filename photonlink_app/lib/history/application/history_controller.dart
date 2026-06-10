import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../protocols/transfer_method.dart';
import '../../services/storage/preferences_service.dart';
import '../data/persistent_history_repository.dart';
import '../domain/transfer_record.dart';

/// Loads and filters transfer history records.
class HistoryController extends AsyncNotifier<List<TransferRecord>> {
  @override
  Future<List<TransferRecord>> build() {
    return ref.watch(historyRepositoryProvider).fetchAll();
  }

  List<TransferRecord> filtered(TransferMethod? method) {
    final records = state.valueOrNull ?? [];
    if (method == null) return records;
    return records.where((r) => r.method == method).toList();
  }
}

final historyRepositoryProvider = Provider<PersistentHistoryRepository>(
  (ref) => PersistentHistoryRepository(ref.watch(preferencesServiceProvider)),
);

final historyProvider =
    AsyncNotifierProvider<HistoryController, List<TransferRecord>>(
  HistoryController.new,
);

/// Currently selected method filter (null = show all).
final historyFilterProvider = StateProvider<TransferMethod?>(
  (ref) => null,
);
