import 'transfer_packet.dart';

/// Lifecycle state of a transfer session.
enum TransferSessionState {
  idle,
  preparing,
  transmitting,
  receiving,
  reconstructing,
  completed,
  failed,
}

/// Describes an active or completed transfer session.
class TransferSession {
  const TransferSession({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.totalChunks,
    required this.sha256,
    required this.mimeType,
    required this.state,
    this.receivedChunks = const {},
    this.progress = 0.0,
    this.errorMessage,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String fileName;
  final int fileSize;
  final int totalChunks;
  final String sha256;
  final String mimeType;
  final TransferSessionState state;
  final Set<int> receivedChunks;
  final double progress;
  final String? errorMessage;
  final DateTime? startedAt;
  final DateTime? completedAt;

  TransferSession copyWith({
    String? id,
    String? fileName,
    int? fileSize,
    int? totalChunks,
    String? sha256,
    String? mimeType,
    TransferSessionState? state,
    Set<int>? receivedChunks,
    double? progress,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return TransferSession(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      totalChunks: totalChunks ?? this.totalChunks,
      sha256: sha256 ?? this.sha256,
      mimeType: mimeType ?? this.mimeType,
      state: state ?? this.state,
      receivedChunks: receivedChunks ?? this.receivedChunks,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Builds a session from a metadata packet.
  factory TransferSession.fromMetadata(
    MetadataPacket metadata, {
    TransferSessionState state = TransferSessionState.receiving,
  }) {
    return TransferSession(
      id: metadata.sessionId,
      fileName: metadata.fileName,
      fileSize: metadata.fileSize,
      totalChunks: metadata.totalChunks,
      sha256: metadata.sha256,
      mimeType: metadata.mimeType,
      state: state,
      startedAt: DateTime.now(),
    );
  }
}
