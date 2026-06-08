import 'dart:typed_data';

import '../../protocols/interfaces/reliability/transfer_diagnostics.dart';
import '../../protocols/interfaces/transfer_session.dart';
import '../../protocols/transfer_method.dart';

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
    this.method = TransferMethod.qr,
    this.session,
    this.currentFrameIndex = 0,
    this.totalFrames = 0,
    this.loopCount = 0,
    this.framesPerSecond = 2.0,
    this.currentQrFrame,
    this.currentColorMatrixRaster,
    this.errorMessage,
    this.filePath,
    this.historyRecordId,
    this.diagnostics = const TransferDiagnostics(),
  });

  final TransferPhase phase;
  final TransferMethod method;
  final TransferSession? session;
  final int currentFrameIndex;
  final int totalFrames;
  final int loopCount;
  final double framesPerSecond;
  final String? currentQrFrame;
  final Uint8List? currentColorMatrixRaster;
  final String? errorMessage;
  final String? filePath;
  final String? historyRecordId;
  final TransferDiagnostics diagnostics;

  SenderTransferState copyWith({
    TransferPhase? phase,
    TransferMethod? method,
    TransferSession? session,
    int? currentFrameIndex,
    int? totalFrames,
    int? loopCount,
    double? framesPerSecond,
    String? currentQrFrame,
    Uint8List? currentColorMatrixRaster,
    String? errorMessage,
    String? filePath,
    String? historyRecordId,
    TransferDiagnostics? diagnostics,
  }) {
    return SenderTransferState(
      phase: phase ?? this.phase,
      method: method ?? this.method,
      session: session ?? this.session,
      currentFrameIndex: currentFrameIndex ?? this.currentFrameIndex,
      totalFrames: totalFrames ?? this.totalFrames,
      loopCount: loopCount ?? this.loopCount,
      framesPerSecond: framesPerSecond ?? this.framesPerSecond,
      currentQrFrame: currentQrFrame ?? this.currentQrFrame,
      currentColorMatrixRaster:
          currentColorMatrixRaster ?? this.currentColorMatrixRaster,
      errorMessage: errorMessage ?? this.errorMessage,
      filePath: filePath ?? this.filePath,
      historyRecordId: historyRecordId ?? this.historyRecordId,
      diagnostics: diagnostics ?? this.diagnostics,
    );
  }
}

/// Receiver-side state.
class ReceiverTransferState {
  const ReceiverTransferState({
    this.phase = TransferPhase.idle,
    this.method = TransferMethod.qr,
    this.session,
    this.receivedChunks = 0,
    this.totalChunks = 0,
    this.progress = 0.0,
    this.outputPath,
    this.integrityValid,
    this.errorMessage,
    this.duplicatesIgnored = 0,
    this.diagnostics = const TransferDiagnostics(),
    this.detectionAccuracy = 0.0,
    this.missingChunks = 0,
  });

  final TransferPhase phase;
  final TransferMethod method;
  final TransferSession? session;
  final int receivedChunks;
  final int totalChunks;
  final double progress;
  final String? outputPath;
  final bool? integrityValid;
  final String? errorMessage;
  final int duplicatesIgnored;
  final TransferDiagnostics diagnostics;
  final double detectionAccuracy;
  final int missingChunks;

  ReceiverTransferState copyWith({
    TransferPhase? phase,
    TransferMethod? method,
    TransferSession? session,
    int? receivedChunks,
    int? totalChunks,
    double? progress,
    String? outputPath,
    bool? integrityValid,
    String? errorMessage,
    int? duplicatesIgnored,
    TransferDiagnostics? diagnostics,
    double? detectionAccuracy,
    int? missingChunks,
  }) {
    return ReceiverTransferState(
      phase: phase ?? this.phase,
      method: method ?? this.method,
      session: session ?? this.session,
      receivedChunks: receivedChunks ?? this.receivedChunks,
      totalChunks: totalChunks ?? this.totalChunks,
      progress: progress ?? this.progress,
      outputPath: outputPath ?? this.outputPath,
      integrityValid: integrityValid ?? this.integrityValid,
      errorMessage: errorMessage ?? this.errorMessage,
      duplicatesIgnored: duplicatesIgnored ?? this.duplicatesIgnored,
      diagnostics: diagnostics ?? this.diagnostics,
      detectionAccuracy: detectionAccuracy ?? this.detectionAccuracy,
      missingChunks: missingChunks ?? this.missingChunks,
    );
  }
}
