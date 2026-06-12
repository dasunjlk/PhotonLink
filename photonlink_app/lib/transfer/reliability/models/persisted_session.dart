import '../../state/transfer_phase.dart';
import 'transfer_diagnostics.dart';

/// Persisted in-progress transfer session for recovery/resume.
class PersistedSession {
  const PersistedSession({
    required this.sessionId,
    required this.role,
    required this.phase,
    required this.fileName,
    required this.fileSize,
    required this.totalChunks,
    required this.sha256,
    required this.mimeType,
    required this.receivedChunkIds,
    required this.acknowledgedChunkIds,
    required this.progress,
    required this.diagnostics,
    this.senderFilePath,
    this.sessionKeyBase64,
    this.keyExchangePayload,
    this.updatedAt,
  });

  final String sessionId;
  final TransferRole role;
  final TransferPhase phase;
  final String fileName;
  final int fileSize;
  final int totalChunks;
  final String sha256;
  final String mimeType;
  final List<int> receivedChunkIds;
  final List<int> acknowledgedChunkIds;
  final double progress;
  final TransferDiagnostics diagnostics;
  final String? senderFilePath;
  final String? sessionKeyBase64;
  final String? keyExchangePayload;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'role': role.name,
        'phase': phase.name,
        'fileName': fileName,
        'fileSize': fileSize,
        'totalChunks': totalChunks,
        'sha256': sha256,
        'mimeType': mimeType,
        'receivedChunkIds': receivedChunkIds,
        'acknowledgedChunkIds': acknowledgedChunkIds,
        'progress': progress,
        'diagnostics': diagnostics.toJson(),
        if (senderFilePath != null) 'senderFilePath': senderFilePath,
        if (sessionKeyBase64 != null) 'sessionKeyBase64': sessionKeyBase64,
        if (keyExchangePayload != null) 'keyExchangePayload': keyExchangePayload,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  factory PersistedSession.fromJson(Map<String, dynamic> json) {
    return PersistedSession(
      sessionId: json['sessionId'] as String,
      role: TransferRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => TransferRole.receiver,
      ),
      phase: TransferPhase.values.firstWhere(
        (p) => p.name == json['phase'],
        orElse: () => TransferPhase.idle,
      ),
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      totalChunks: json['totalChunks'] as int,
      sha256: json['sha256'] as String,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      receivedChunkIds: (json['receivedChunkIds'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      acknowledgedChunkIds: (json['acknowledgedChunkIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      diagnostics: TransferDiagnostics.fromJson(
        json['diagnostics'] as Map<String, dynamic>? ?? {},
      ),
      senderFilePath: json['senderFilePath'] as String?,
      sessionKeyBase64: json['sessionKeyBase64'] as String?,
      keyExchangePayload: json['keyExchangePayload'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  PersistedSession copyWith({
    TransferPhase? phase,
    List<int>? receivedChunkIds,
    List<int>? acknowledgedChunkIds,
    double? progress,
    TransferDiagnostics? diagnostics,
    DateTime? updatedAt,
  }) {
    return PersistedSession(
      sessionId: sessionId,
      role: role,
      phase: phase ?? this.phase,
      fileName: fileName,
      fileSize: fileSize,
      totalChunks: totalChunks,
      sha256: sha256,
      mimeType: mimeType,
      receivedChunkIds: receivedChunkIds ?? this.receivedChunkIds,
      acknowledgedChunkIds:
          acknowledgedChunkIds ?? this.acknowledgedChunkIds,
      progress: progress ?? this.progress,
      diagnostics: diagnostics ?? this.diagnostics,
      senderFilePath: senderFilePath,
      sessionKeyBase64: sessionKeyBase64,
      keyExchangePayload: keyExchangePayload,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
