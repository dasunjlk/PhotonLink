import '../../protocols/interfaces/transfer_session.dart';

/// High-level transfer phase for UI and controllers.
enum TransferPhase {
  idle,
  preparing,
  transmitting,
  receiving,
  reconstructing,
  completed,
  failed,
}

/// Sender-side state.
class SenderTransferState {
  const SenderTransferState({
    this.phase = TransferPhase.idle,
    this.session,
    this.currentFrameIndex = 0,
    this.totalFrames = 0,
    this.loopCount = 0,
    this.framesPerSecond = 2.0,
    this.currentFrameData,
    this.errorMessage,
    this.filePath,
    this.historyRecordId,
  });

  final TransferPhase phase;
  final TransferSession? session;
  final int currentFrameIndex;
  final int totalFrames;
  final int loopCount;
  final double framesPerSecond;
  final String? currentFrameData;
  final String? errorMessage;
  final String? filePath;
  final String? historyRecordId;

  SenderTransferState copyWith({
    TransferPhase? phase,
    TransferSession? session,
    int? currentFrameIndex,
    int? totalFrames,
    int? loopCount,
    double? framesPerSecond,
    String? currentFrameData,
    String? errorMessage,
    String? filePath,
    String? historyRecordId,
  }) {
    return SenderTransferState(
      phase: phase ?? this.phase,
      session: session ?? this.session,
      currentFrameIndex: currentFrameIndex ?? this.currentFrameIndex,
      totalFrames: totalFrames ?? this.totalFrames,
      loopCount: loopCount ?? this.loopCount,
      framesPerSecond: framesPerSecond ?? this.framesPerSecond,
      currentFrameData: currentFrameData ?? this.currentFrameData,
      errorMessage: errorMessage ?? this.errorMessage,
      filePath: filePath ?? this.filePath,
      historyRecordId: historyRecordId ?? this.historyRecordId,
    );
  }
}

/// Receiver-side state.
class ReceiverTransferState {
  const ReceiverTransferState({
    this.phase = TransferPhase.idle,
    this.session,
    this.receivedChunks = 0,
    this.totalChunks = 0,
    this.progress = 0.0,
    this.outputPath,
    this.integrityValid,
    this.errorMessage,
    this.duplicatesIgnored = 0,
  });

  final TransferPhase phase;
  final TransferSession? session;
  final int receivedChunks;
  final int totalChunks;
  final double progress;
  final String? outputPath;
  final bool? integrityValid;
  final String? errorMessage;
  final int duplicatesIgnored;

  ReceiverTransferState copyWith({
    TransferPhase? phase,
    TransferSession? session,
    int? receivedChunks,
    int? totalChunks,
    double? progress,
    String? outputPath,
    bool? integrityValid,
    String? errorMessage,
    int? duplicatesIgnored,
  }) {
    return ReceiverTransferState(
      phase: phase ?? this.phase,
      session: session ?? this.session,
      receivedChunks: receivedChunks ?? this.receivedChunks,
      totalChunks: totalChunks ?? this.totalChunks,
      progress: progress ?? this.progress,
      outputPath: outputPath ?? this.outputPath,
      integrityValid: integrityValid ?? this.integrityValid,
      errorMessage: errorMessage ?? this.errorMessage,
      duplicatesIgnored: duplicatesIgnored ?? this.duplicatesIgnored,
    );
  }
}
