import 'dart:convert';

import '../../protocols/transfer_method.dart';
import '../../services/storage/preferences_service.dart';
import '../domain/transfer_record.dart';

/// SharedPreferences-backed transfer history (v3 schema with v2 migration).
class PersistentHistoryRepository {
  PersistentHistoryRepository(this._prefs);

  final PreferencesService _prefs;
  static const _storageKey = 'transfer_history_v3';
  static const _legacyV2Key = 'transfer_history_v2';

  Future<List<TransferRecord>> fetchAll() async {
    await _migrateFromV2IfNeeded();
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

  Future<void> _migrateFromV2IfNeeded() async {
    if (_prefs.getString(_storageKey) != null) return;
    final v2 = _prefs.getString(_legacyV2Key);
    if (v2 == null || v2.isEmpty) return;
    try {
      final list = jsonDecode(v2) as List<dynamic>;
      final migrated = list
          .map((e) => _recordFromJson(e as Map<String, dynamic>))
          .toList();
      await _saveAll(migrated);
    } catch (_) {
      // ignore corrupt legacy data
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
    double? transferSpeedBytesPerSec,
    double? compressionRatio,
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
      compressionUsed: existing.compressionUsed,
      encryptionUsed: existing.encryptionUsed,
      compressionRatio: compressionRatio ?? existing.compressionRatio,
      transferSpeedBytesPerSec:
          transferSpeedBytesPerSec ?? existing.transferSpeedBytesPerSec,
      protocolVersion: existing.protocolVersion,
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
        'compressionUsed': r.compressionUsed,
        'encryptionUsed': r.encryptionUsed,
        if (r.compressionRatio != null) 'compressionRatio': r.compressionRatio,
        if (r.transferSpeedBytesPerSec != null)
          'transferSpeedBytesPerSec': r.transferSpeedBytesPerSec,
        'protocolVersion': r.protocolVersion,
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
      compressionUsed: json['compressionUsed'] as bool? ?? false,
      encryptionUsed: json['encryptionUsed'] as bool? ?? false,
      compressionRatio: (json['compressionRatio'] as num?)?.toDouble(),
      transferSpeedBytesPerSec:
          (json['transferSpeedBytesPerSec'] as num?)?.toDouble(),
      protocolVersion: json['protocolVersion'] as int? ?? 1,
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
      protocolVersion: 2,
    ),
  ];
}
