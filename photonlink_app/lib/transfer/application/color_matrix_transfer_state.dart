import 'dart:typed_data';

import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/reliability/transfer_diagnostics.dart';
import '../../protocols/interfaces/transfer_session.dart';
import 'transfer_state.dart';

export 'transfer_state.dart' show TransferPhase;

/// Sender state for Color Matrix optical transfer.
class ColorMatrixSenderState {
  const ColorMatrixSenderState({
    this.phase = TransferPhase.idle,
    this.session,
    this.currentFrameIndex = 0,
    this.totalFrames = 0,
    this.loopCount = 0,
    this.framesPerSecond = 4.0,
    this.currentColorMatrixRaster,
    this.errorMessage,
    this.filePath,
    this.diagnostics = const TransferDiagnostics(),
    this.compression = CompressionType.none,
    this.encryption = EncryptionMode.disabled,
  });

  final TransferPhase phase;
  final TransferSession? session;
  final int currentFrameIndex;
  final int totalFrames;
  final int loopCount;
  final double framesPerSecond;
  final Uint8List? currentColorMatrixRaster;
  final String? errorMessage;
  final String? filePath;
  final TransferDiagnostics diagnostics;
  final CompressionType compression;
  final EncryptionMode encryption;

  ColorMatrixSenderState copyWith({
    TransferPhase? phase,
    TransferSession? session,
    int? currentFrameIndex,
    int? totalFrames,
    int? loopCount,
    double? framesPerSecond,
    Uint8List? currentColorMatrixRaster,
    String? errorMessage,
    String? filePath,
    TransferDiagnostics? diagnostics,
    CompressionType? compression,
    EncryptionMode? encryption,
  }) {
    return ColorMatrixSenderState(
      phase: phase ?? this.phase,
      session: session ?? this.session,
      currentFrameIndex: currentFrameIndex ?? this.currentFrameIndex,
      totalFrames: totalFrames ?? this.totalFrames,
      loopCount: loopCount ?? this.loopCount,
      framesPerSecond: framesPerSecond ?? this.framesPerSecond,
      currentColorMatrixRaster:
          currentColorMatrixRaster ?? this.currentColorMatrixRaster,
      errorMessage: errorMessage ?? this.errorMessage,
      filePath: filePath ?? this.filePath,
      diagnostics: diagnostics ?? this.diagnostics,
      compression: compression ?? this.compression,
      encryption: encryption ?? this.encryption,
    );
  }
}

/// Receiver state for Color Matrix optical transfer.
class ColorMatrixReceiverState {
  const ColorMatrixReceiverState({
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
    this.detectionAccuracy = 0.0,
    this.missingChunks = 0,
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
  final double detectionAccuracy;
  final int missingChunks;

  ColorMatrixReceiverState copyWith({
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
    double? detectionAccuracy,
    int? missingChunks,
  }) {
    return ColorMatrixReceiverState(
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
      detectionAccuracy: detectionAccuracy ?? this.detectionAccuracy,
      missingChunks: missingChunks ?? this.missingChunks,
    );
  }
}
