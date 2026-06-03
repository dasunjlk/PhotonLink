import 'dart:convert';

import '../../protocols/transfer_method.dart';
import '../../services/storage/preferences_service.dart';
import '../domain/transfer_record.dart';

/// SharedPreferences-backed transfer history repository (v2 schema).
class PersistentHistoryRepository {
  PersistentHistoryRepository(this._prefs);

  final PreferencesService _prefs;
  static const _storageKey = 'transfer_history_v2';

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

  Future<bool> updateRecord(
    String id, {
    TransferStatus? status,
    int? retryCount,
    int? durationMs,
    String? failureReason,
  }) async {
    final records = await fetchAll();
    final index = records.indexWhere((r) => r.id == id);
    if (index < 0) return false;
    final existing = records[index];
    records[index] = TransferRecord(
      id: existing.id,
      fileName: existing.fileName,
      method: existing.method,
      sizeBytes: existing.sizeBytes,
      status: status ?? existing.status,
      timestamp: existing.timestamp,
      direction: existing.direction,
      sessionId: existing.sessionId,
      durationMs: durationMs ?? existing.durationMs,
      retryCount: retryCount ?? existing.retryCount,
      failureReason: failureReason ?? existing.failureReason,
    );
    await _saveAll(records);
    return true;
  }

  @Deprecated('Use updateRecord')
  Future<bool> updateStatus(String id, TransferStatus status) =>
      updateRecord(id, status: status);

  Future<void> clearAll() async {
    await _prefs.setString(_storageKey, '[]');
  }

  Future<void> _saveAll(List<TransferRecord> records) async {
    final json = records.map(_recordToJson).toList();
    await _prefs.setString(_storageKey, jsonEncode(json));
  }

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
        if (r.sessionId != null) 'sessionId': r.sessionId,
        'durationMs': r.durationMs,
        'retryCount': r.retryCount,
        if (r.failureReason != null) 'failureReason': r.failureReason,
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
      sessionId: json['sessionId'] as String?,
      durationMs: json['durationMs'] as int? ?? 0,
      retryCount: json['retryCount'] as int? ?? 0,
      failureReason: json['failureReason'] as String?,
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
      sessionId: 'seed-session',
    ),
  ];
}
