import 'dart:typed_data';

import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/reliability/transfer_diagnostics.dart';
import '../../protocols/interfaces/transfer_session.dart';
import '../adaptive/adaptive_state.dart';
import '../adaptive/lighting_compensation_manager.dart';
import '../adaptive/models/quality_score.dart';
import '../adaptive/models/transport_profile.dart';
import 'transfer_state.dart';

export 'transfer_state.dart' show TransferPhase;

/// Sender state for Optical Stream continuous transfer.
class OpticalStreamSenderState {
  const OpticalStreamSenderState({
    this.phase = TransferPhase.idle,
    this.session,
    this.currentFrameIndex = 0,
    this.totalFrames = 0,
    this.loopCount = 0,
    this.framesPerSecond = 8.0,
    this.frameRate = 8.0,
    this.throughputBytesPerSec = 0.0,
    this.currentOpticalRaster,
    this.errorMessage,
    this.filePath,
    this.diagnostics = const FrameDiagnostics(),
    this.compression = CompressionType.none,
    this.encryption = EncryptionMode.disabled,
    this.gridSize = 24,
    this.bitsPerCell = 1,
    this.transportProfile = TransportProfile.balanced,
    this.qualityScore = QualityScore.unknown,
    this.historyRecordId,
    this.syncLocked = false,
  });

  final TransferPhase phase;
  final TransferSession? session;
  final int currentFrameIndex;
  final int totalFrames;
  final int loopCount;
  final double framesPerSecond;
  final double frameRate;
  final double throughputBytesPerSec;
  final Uint8List? currentOpticalRaster;
  final String? errorMessage;
  final String? filePath;
  final FrameDiagnostics diagnostics;
  final CompressionType compression;
  final EncryptionMode encryption;
  final int gridSize;
  final int bitsPerCell;
  final TransportProfile transportProfile;
  final QualityScore qualityScore;
  final String? historyRecordId;
  final bool syncLocked;

  OpticalStreamSenderState copyWith({
    TransferPhase? phase,
    TransferSession? session,
    int? currentFrameIndex,
    int? totalFrames,
    int? loopCount,
    double? framesPerSecond,
    double? frameRate,
    double? throughputBytesPerSec,
    Uint8List? currentOpticalRaster,
    String? errorMessage,
    String? filePath,
    FrameDiagnostics? diagnostics,
    CompressionType? compression,
    EncryptionMode? encryption,
    int? gridSize,
    int? bitsPerCell,
    TransportProfile? transportProfile,
    QualityScore? qualityScore,
    String? historyRecordId,
    bool? syncLocked,
  }) {
    return OpticalStreamSenderState(
      phase: phase ?? this.phase,
      session: session ?? this.session,
      currentFrameIndex: currentFrameIndex ?? this.currentFrameIndex,
      totalFrames: totalFrames ?? this.totalFrames,
      loopCount: loopCount ?? this.loopCount,
      framesPerSecond: framesPerSecond ?? this.framesPerSecond,
      frameRate: frameRate ?? this.frameRate,
      throughputBytesPerSec:
          throughputBytesPerSec ?? this.throughputBytesPerSec,
      currentOpticalRaster: currentOpticalRaster ?? this.currentOpticalRaster,
      errorMessage: errorMessage ?? this.errorMessage,
      filePath: filePath ?? this.filePath,
      diagnostics: diagnostics ?? this.diagnostics,
      compression: compression ?? this.compression,
      encryption: encryption ?? this.encryption,
      gridSize: gridSize ?? this.gridSize,
      bitsPerCell: bitsPerCell ?? this.bitsPerCell,
      transportProfile: transportProfile ?? this.transportProfile,
      qualityScore: qualityScore ?? this.qualityScore,
      historyRecordId: historyRecordId ?? this.historyRecordId,
      syncLocked: syncLocked ?? this.syncLocked,
    );
  }
}

/// Receiver state for Optical Stream continuous transfer.
class OpticalStreamReceiverState {
  const OpticalStreamReceiverState({
    this.phase = TransferPhase.idle,
    this.session,
    this.receivedChunks = 0,
    this.totalChunks = 0,
    this.progress = 0.0,
    this.outputPath,
    this.integrityValid,
    this.errorMessage,
    this.duplicatesIgnored = 0,
    this.diagnostics = const FrameDiagnostics(),
    this.detectionAccuracy = 0.0,
    this.missingChunks = 0,
    this.qualityScore = QualityScore.unknown,
    this.lighting = const LightingRecommendation(),
    this.adaptive = const AdaptiveState(),
    this.gridSize = 24,
    this.bitsPerCell = 1,
    this.transportProfile = TransportProfile.balanced,
    this.historyRecordId,
    this.frameRate = 0.0,
    this.throughputBytesPerSec = 0.0,
    this.recoveredPackets = 0,
    this.recoveryRate = 0.0,
    this.droppedFrames = 0,
    this.resyncCount = 0,
    this.syncLocked = false,
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
  final FrameDiagnostics diagnostics;
  final double detectionAccuracy;
  final int missingChunks;
  final QualityScore qualityScore;
  final LightingRecommendation lighting;
  final AdaptiveState adaptive;
  final int gridSize;
  final int bitsPerCell;
  final TransportProfile transportProfile;
  final String? historyRecordId;
  final double frameRate;
  final double throughputBytesPerSec;
  final int recoveredPackets;
  final double recoveryRate;
  final int droppedFrames;
  final int resyncCount;
  final bool syncLocked;

  OpticalStreamReceiverState copyWith({
    TransferPhase? phase,
    TransferSession? session,
    int? receivedChunks,
    int? totalChunks,
    double? progress,
    String? outputPath,
    bool? integrityValid,
    String? errorMessage,
    int? duplicatesIgnored,
    FrameDiagnostics? diagnostics,
    double? detectionAccuracy,
    int? missingChunks,
    QualityScore? qualityScore,
    LightingRecommendation? lighting,
    AdaptiveState? adaptive,
    int? gridSize,
    int? bitsPerCell,
    TransportProfile? transportProfile,
    String? historyRecordId,
    double? frameRate,
    double? throughputBytesPerSec,
    int? recoveredPackets,
    double? recoveryRate,
    int? droppedFrames,
    int? resyncCount,
    bool? syncLocked,
  }) {
    return OpticalStreamReceiverState(
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
      qualityScore: qualityScore ?? this.qualityScore,
      lighting: lighting ?? this.lighting,
      adaptive: adaptive ?? this.adaptive,
      gridSize: gridSize ?? this.gridSize,
      bitsPerCell: bitsPerCell ?? this.bitsPerCell,
      transportProfile: transportProfile ?? this.transportProfile,
      historyRecordId: historyRecordId ?? this.historyRecordId,
      frameRate: frameRate ?? this.frameRate,
      throughputBytesPerSec:
          throughputBytesPerSec ?? this.throughputBytesPerSec,
      recoveredPackets: recoveredPackets ?? this.recoveredPackets,
      recoveryRate: recoveryRate ?? this.recoveryRate,
      droppedFrames: droppedFrames ?? this.droppedFrames,
      resyncCount: resyncCount ?? this.resyncCount,
      syncLocked: syncLocked ?? this.syncLocked,
    );
  }
}
