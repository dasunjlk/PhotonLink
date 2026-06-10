import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Stores received chunk payloads on disk for resume (O(1) per chunk).
class ReceivedChunkStore {
  static const _rootFolder = 'photonlink_sessions';

  Future<Directory> _sessionDir(String sessionId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_rootFolder/$sessionId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> saveChunk({
    required String sessionId,
    required int chunkId,
    required Uint8List payload,
  }) async {
    final dir = await _sessionDir(sessionId);
    final file = File('${dir.path}/$chunkId.bin');
    await file.writeAsBytes(payload, flush: true);
  }

  Future<Uint8List?> loadChunk({
    required String sessionId,
    required int chunkId,
  }) async {
    final dir = await _sessionDir(sessionId);
    final file = File('${dir.path}/$chunkId.bin');
    if (!await file.exists()) return null;
    return Uint8List.fromList(await file.readAsBytes());
  }

  Future<Set<int>> listChunkIds(String sessionId) async {
    final dir = await _sessionDir(sessionId);
    final ids = <int>{};
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.bin')) {
        final name = entity.uri.pathSegments.last.replaceAll('.bin', '');
        final id = int.tryParse(name);
        if (id != null) ids.add(id);
      }
    }
    return ids;
  }

  Future<void> removeSession(String sessionId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_rootFolder/$sessionId');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> saveMeta(String sessionId, Map<String, dynamic> meta) async {
    final dir = await _sessionDir(sessionId);
    await File('${dir.path}/meta.json')
        .writeAsString(jsonEncode(meta), flush: true);
  }
}
