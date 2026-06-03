import 'dart:convert';

import '../../protocols/interfaces/reliability/session_persistence_manager.dart';
import '../../services/storage/preferences_service.dart';
import '../reliability/models/persisted_session.dart';
import '../state/transfer_phase.dart';

/// SharedPreferences index of in-progress sessions.
class SessionPersistenceManagerImpl implements SessionPersistenceManager {
  SessionPersistenceManagerImpl(this._prefs);

  final PreferencesService _prefs;
  static const _indexKey = 'transfer_sessions_index_v3';

  @override
  Future<void> save(PersistedSession session) async {
    final key = _sessionKey(session.sessionId);
    await _prefs.setString(key, jsonEncode(session.toJson()));
    final index = _loadIndex();
    index[session.sessionId] = {
      'role': session.role.name,
      'phase': session.phase.name,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _prefs.setString(_indexKey, jsonEncode(index));
  }

  @override
  Future<PersistedSession?> load(String sessionId) async {
    final raw = _prefs.getString(_sessionKey(sessionId));
    if (raw == null) return null;
    try {
      return PersistedSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PersistedSession>> listResumable() async {
    final index = _loadIndex();
    final sessions = <PersistedSession>[];
    for (final id in index.keys) {
      final s = await load(id);
      if (s != null && !s.phase.isTerminal) sessions.add(s);
    }
    return sessions;
  }

  @override
  Future<void> remove(String sessionId) async {
    await _prefs.remove(_sessionKey(sessionId));
    final index = _loadIndex();
    index.remove(sessionId);
    await _prefs.setString(_indexKey, jsonEncode(index));
  }

  @override
  Future<PersistedSession?> findLatestResumable({
    required TransferRole role,
  }) async {
    final all = await listResumable();
    final filtered = all.where((s) => s.role == role).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) {
      final at = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return filtered.first;
  }

  String _sessionKey(String sessionId) => 'transfer_session_v3_$sessionId';

  Map<String, dynamic> _loadIndex() {
    final raw = _prefs.getString(_indexKey);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return {};
    }
  }
}
