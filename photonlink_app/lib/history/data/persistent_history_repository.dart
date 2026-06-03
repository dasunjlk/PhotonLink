import 'dart:convert';

import '../../protocols/transfer_method.dart';
import '../../services/storage/preferences_service.dart';
import '../domain/transfer_record.dart';

/// SharedPreferences-backed transfer history repository.
class PersistentHistoryRepository {
  PersistentHistoryRepository(this._prefs);

  final PreferencesService _prefs;
  static const _storageKey = 'transfer_history_v1';

  Future<List<TransferRecord>> fetchAll() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return _defaultSeedIfEmpty();
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => _recordFromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  Future<void> addRecord(TransferRecord record) async {
    final records = await fetchAll();
    records.insert(0, record);
    await _saveAll(records);
  }

  /// Updates status of an existing record by id.
  Future<bool> updateStatus(String id, TransferStatus status) async {
    final records = await fetchAll();
    final index = records.indexWhere((r) => r.id == id);
    if (index < 0) return false;
    final existing = records[index];
    records[index] = TransferRecord(
      id: existing.id,
      fileName: existing.fileName,
      method: existing.method,
      sizeBytes: existing.sizeBytes,
      status: status,
      timestamp: existing.timestamp,
      direction: existing.direction,
    );
    await _saveAll(records);
    return true;
  }

  Future<void> clearAll() async {
    await _prefs.setString(_storageKey, '[]');
  }

  Future<void> _saveAll(List<TransferRecord> records) async {
    final json = records.map(_recordToJson).toList();
    await _prefs.setString(_storageKey, jsonEncode(json));
  }

  /// Seeds demo records only on first launch (empty storage).
  Future<List<TransferRecord>> _defaultSeedIfEmpty() async {
    final seeded = _seededRecords;
    await _saveAll(seeded);
    return seeded;
  }

  static Map<String, dynamic> _recordToJson(TransferRecord r) => {
        'id': r.id,
        'fileName': r.fileName,
        'method': r.method.id,
        'sizeBytes': r.sizeBytes,
        'status': r.status.name,
        'timestamp': r.timestamp.toIso8601String(),
        'direction': r.direction.name,
      };

  static TransferRecord _recordFromJson(Map<String, dynamic> json) {
    return TransferRecord(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      method: TransferMethod.values.firstWhere(
        (m) => m.id == json['method'],
        orElse: () => TransferMethod.qr,
      ),
      sizeBytes: json['sizeBytes'] as int,
      status: TransferStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TransferStatus.success,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      direction: TransferDirection.values.firstWhere(
        (d) => d.name == json['direction'],
        orElse: () => TransferDirection.sent,
      ),
    );
  }

  static final List<TransferRecord> _seededRecords = [
    TransferRecord(
      id: 'seed-1',
      fileName: 'notes.txt',
      method: TransferMethod.qr,
      sizeBytes: 4096,
      status: TransferStatus.success,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      direction: TransferDirection.received,
    ),
  ];
}
