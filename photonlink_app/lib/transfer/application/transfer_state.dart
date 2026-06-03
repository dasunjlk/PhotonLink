import '../../protocols/interfaces/transfer_session.dart';
import '../reliability/models/transfer_diagnostics.dart';
import '../state/transfer_phase.dart';

export '../state/transfer_phase.dart';

/// Sender-side state with Phase 3 diagnostics.
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
    this.diagnostics = const TransferDiagnostics(),
    this.missingCount = 0,
    this.roundNumber = 0,
    this.resumableSession,
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
  final TransferDiagnostics diagnostics;
  final int missingCount;
  final int roundNumber;
  final String? resumableSession;

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
    TransferDiagnostics? diagnostics,
    int? missingCount,
    int? roundNumber,
    String? resumableSession,
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
      diagnostics: diagnostics ?? this.diagnostics,
      missingCount: missingCount ?? this.missingCount,
      roundNumber: roundNumber ?? this.roundNumber,
      resumableSession: resumableSession ?? this.resumableSession,
    );
  }
}

/// Receiver-side state with Phase 3 diagnostics.
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
    this.diagnostics = const TransferDiagnostics(),
    this.missingCount = 0,
    this.roundNumber = 0,
    this.resumableSession,
    this.statusMessage,
    this.currentFrameData,
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
  final TransferDiagnostics diagnostics;
  final int missingCount;
  final int roundNumber;
  final String? resumableSession;
  final String? statusMessage;
  final String? currentFrameData;

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
    TransferDiagnostics? diagnostics,
    int? missingCount,
    int? roundNumber,
    String? resumableSession,
    String? statusMessage,
    String? currentFrameData,
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
      diagnostics: diagnostics ?? this.diagnostics,
      missingCount: missingCount ?? this.missingCount,
      roundNumber: roundNumber ?? this.roundNumber,
      resumableSession: resumableSession ?? this.resumableSession,
      statusMessage: statusMessage ?? this.statusMessage,
      currentFrameData: currentFrameData ?? this.currentFrameData,
    );
  }
}
