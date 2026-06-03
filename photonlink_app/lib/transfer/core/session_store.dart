import 'dart:convert';

import '../../services/storage/preferences_service.dart';

/// Persisted snapshot of an in-progress transfer session.
class SessionSnapshot {
  const SessionSnapshot({
    required this.sessionId,
    required this.progress,
    required this.receivedChunkIds,
    this.fileName,
    this.totalChunks,
    this.direction,
  });

  final String sessionId;
  final double progress;
  final List<int> receivedChunkIds;
  final String? fileName;
  final int? totalChunks;
  final String? direction;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'progress': progress,
        'receivedChunkIds': receivedChunkIds,
        if (fileName != null) 'fileName': fileName,
        if (totalChunks != null) 'totalChunks': totalChunks,
        if (direction != null) 'direction': direction,
      };

  factory SessionSnapshot.fromJson(Map<String, dynamic> json) {
    return SessionSnapshot(
      sessionId: json['sessionId'] as String,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      receivedChunkIds: (json['receivedChunkIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      fileName: json['fileName'] as String?,
      totalChunks: json['totalChunks'] as int?,
      direction: json['direction'] as String?,
    );
  }
}

/// Persists transfer progress for future resume support.
class SessionStore {
  SessionStore(this._prefs);

  final PreferencesService _prefs;
  static const _keyPrefix = 'transfer_session_';

  String _key(String sessionId) => '$_keyPrefix$sessionId';

  Future<void> save(SessionSnapshot snapshot) async {
    await _prefs.setString(
      _key(snapshot.sessionId),
      jsonEncode(snapshot.toJson()),
    );
  }

  SessionSnapshot? load(String sessionId) {
    final raw = _prefs.getString(_key(sessionId));
    if (raw == null) return null;
    try {
      return SessionSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String sessionId) async {
    await _prefs.remove(_key(sessionId));
  }
}
