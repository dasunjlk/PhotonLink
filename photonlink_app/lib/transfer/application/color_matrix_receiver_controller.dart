import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../history/application/history_controller.dart';
import '../../history/domain/transfer_record.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../protocols/interfaces/transfer_session.dart';
import '../../protocols/transport_registry.dart';
import '../../protocols/transfer_method.dart';
import '../../settings/application/settings_controller.dart';
import '../state/transfer_phase.dart';
import '../adaptive/adaptive_engine_providers.dart';
import '../color_matrix/color_matrix_frame.dart';
import '../color_matrix/color_matrix_frame_codec.dart';
import '../color_matrix/color_matrix_transport.dart';
import '../../services/core/core_providers.dart';
import '../../services/core/core_service.dart';
import '../../services/core/fec_service.dart';
import '../../services/core/impl/dart_fec_service.dart';
import '../core/payload_pipeline.dart';
import '../core/reconstruction_engine.dart';
import '../core/transfer_limits.dart';
import '../fec/fec_configuration_factory.dart';
import '../fec/recovery_engine.dart';
import '../diagnostics/diagnostics_collector.dart';
import '../security/encryption_key_provider.dart';
import '../security/session_key_exchange.dart';
import 'color_matrix_transfer_state.dart';
import 'transfer_providers.dart';

/// Color Matrix receiver: camera frames → decode → reconstruct → restore.
class ColorMatrixReceiverController extends Notifier<ColorMatrixReceiverState> {
  final _recon = ReconstructionEngine();
  final _fecEngine = RecoveryEngine();
  FecService get _fecRecovery => DartFecService(engine: _fecEngine);
  final _fecFactory = const FecConfigurationFactory();
  final _keyProvider = EncryptionKeyProvider();
  final _keyExchange = SessionKeyExchange();
  late FrameDiagnosticsCollector _diagnostics;
  ColorMatrixTransport? _sessionTransport;
  bool _finalizing = false;
  DateTime? _receiveStartedAt;
  String? _historyId;

  @override
  ColorMatrixReceiverState build() {
    _diagnostics = ref.read(colorMatrixDiagnosticsCollectorProvider);
    return const ColorMatrixReceiverState();
  }

  PayloadPipeline get _pipeline => ref.read(payloadPipelineProvider);
  CoreService get _core => ref.read(coreServiceProvider);

  ColorMatrixTransport get _activeTransport =>
      _sessionTransport ??
      ref.read<ColorMatrixTransport>(colorMatrixTransportProvider);

  ColorMatrixFrameCodec get _frameCodec =>
      _activeTransport.decoder as ColorMatrixFrameCodec;

  Future<void> startReceiving({
    int cameraWidth = 0,
    int cameraHeight = 0,
  }) async {
    _recon.reset();
    _keyProvider.clear();
    _diagnostics.reset();
    _finalizing = false;
    _receiveStartedAt = DateTime.now();
    _historyId = null;

    final adaptive = ref.read(colorMatrixReceiverAdaptiveProvider);
    await adaptive.initializeSession(
      cameraWidth: cameraWidth,
      cameraHeight: cameraHeight,
      isReceiver: true,
    );
    final mapped = adaptive.getSessionStartParams();

    final settings = ref.read(settingsProvider);
    _fecRecovery.configure(_fecFactory.fromSettings(settings));
    _sessionTransport = ColorMatrixTransport(
      gridSize: mapped.gridSize,
      bitsPerChannel: mapped.bitsPerChannel,
    );

    var mismatchWarning = adaptive.state.mismatchWarning;
    if (settings.colorMatrixSize != mapped.gridSize ||
        settings.colorBitsPerChannel != mapped.bitsPerChannel) {
      mismatchWarning =
          'Sender/receiver grid may differ — align settings or use matching profiles';
    }

    ref.read(adaptiveStateProvider.notifier).state = adaptive.state.copyWith(
      mismatchWarning: mismatchWarning,
    );

    state = ColorMatrixReceiverState(
      phase: TransferPhase.waitingForReceiver,
      gridSize: mapped.gridSize,
      bitsPerChannel: mapped.bitsPerChannel,
      transportProfile: mapped.profile,
      adaptive: adaptive.state.copyWith(mismatchWarning: mismatchWarning),
      qualityScore: adaptive.state.qualityScore,
      lighting: adaptive.state.lighting,
    );
  }

  void recordBrightnessSample(double avg, {double variance = 0}) {
    ref.read(colorMatrixReceiverAdaptiveProvider).recordBrightness(
          avg,
          variance: variance,
        );
    _syncAdaptiveState();
  }

  void onColorMatrixFrame(
    ColorMatrixFrame raw, {
    double detectionAccuracy = 0,
    required bool detected,
  }) {
    if (_finalizing || state.phase.isTerminal) return;
    if (state.phase == TransferPhase.reconstructing) return;

    final adaptive = ref.read(colorMatrixReceiverAdaptiveProvider);
    adaptive.recordDetection(success: detected, accuracy: detectionAccuracy);

    _diagnostics.recordDetectionAccuracy(detectionAccuracy);
    final stopwatch = Stopwatch()..start();

    final packet = _frameCodec.decodeFrame(raw);
    stopwatch.stop();
    _diagnostics.recordDecodeTime(stopwatch.elapsed);

    adaptive.recordDecode(
      success: packet != null,
      diag: _diagnostics.current,
    );
    _syncAdaptiveState();

    if (packet == null) {
      _diagnostics.recordFrameCorrupted();
      _syncDiagnostics(detectionAccuracy: detectionAccuracy);
      return;
    }

    _handlePacket(packet, detectionAccuracy: detectionAccuracy);
  }

  void _handlePacket(
    TransferPacket packet, {
    required double detectionAccuracy,
  }) {
    switch (packet) {
      case MetadataPacket metadata:
        unawaited(
          _handleMetadata(metadata, detectionAccuracy: detectionAccuracy),
        );
      case DataPacket data:
        unawaited(_handleData(data, detectionAccuracy: detectionAccuracy));
      case ParityPacket parity:
        _handleParity(parity, detectionAccuracy: detectionAccuracy);
      default:
        break;
    }
  }

  Future<void> _handleMetadata(
    MetadataPacket metadata, {
    required double detectionAccuracy,
  }  ) async {
    try {
      TransferLimits.validateMetadata(
        fileName: metadata.fileName,
        fileSize: metadata.fileSize,
        totalChunks: metadata.totalChunks,
        sha256: metadata.sha256,
        maxBytes: TransferLimits.maxColorMatrixFileBytes,
      );
    } catch (_) {
      _diagnostics.recordFrameCorrupted();
      _syncDiagnostics(detectionAccuracy: detectionAccuracy);
      return;
    }

    if (metadata.encryption == EncryptionMode.enabled && !_keyProvider.hasKey) {
      final keyPayload = _frameCodec.lastDecodedKeyExchange;
      if (keyPayload == null) {
        _syncDiagnostics(detectionAccuracy: detectionAccuracy);
        return;
      }
      try {
        final key = await _keyExchange.acceptFromReceiver(keyPayload);
        _keyProvider.setSessionKey(key);
      } catch (_) {
        _diagnostics.recordFrameCorrupted();
        _syncDiagnostics(detectionAccuracy: detectionAccuracy);
        return;
      }
    }

    _recon.ingest(metadata);
    _diagnostics.recordFrameReceived();

    _historyId ??=
        '${metadata.sessionId}-cm-recv-${DateTime.now().millisecondsSinceEpoch}';
    if (_historyId != null) {
      await ref.read(historyRepositoryProvider).addRecord(
            TransferRecord(
              id: _historyId!,
              sessionId: metadata.sessionId,
              fileName: metadata.fileName,
              method: TransferMethod.colorMatrix,
              sizeBytes: metadata.originalSize ?? metadata.fileSize,
              status: TransferStatus.inProgress,
              timestamp: DateTime.now(),
              direction: TransferDirection.received,
              compressionUsed:
                  metadata.compression != CompressionType.none,
              encryptionUsed:
                  metadata.encryption == EncryptionMode.enabled,
              profileUsed: state.transportProfile.id,
              protocolVersion: 4,
            ),
          );
    }

    state = state.copyWith(
      phase: TransferPhase.receiving,
      session: TransferSession(
        id: metadata.sessionId,
        fileName: metadata.fileName,
        fileSize: metadata.originalSize ?? metadata.fileSize,
        totalChunks: metadata.totalChunks,
        sha256: metadata.originalSha256 ?? metadata.sha256,
        mimeType: metadata.mimeType,
        state: TransferSessionState.receiving,
        startedAt: DateTime.now(),
      ),
      totalChunks: metadata.totalChunks,
      historyRecordId: _historyId,
    );
    _syncDiagnostics(detectionAccuracy: detectionAccuracy);
  }

  Future<void> _handleData(
    DataPacket data, {
    required double detectionAccuracy,
  }) async {
    if (!_recon.hasMetadata) {
      _syncDiagnostics(detectionAccuracy: detectionAccuracy);
      return;
    }

    final accepted = _recon.ingest(data);
    if (!accepted) {
      _diagnostics.recordDuplicate();
      state = state.copyWith(
        duplicatesIgnored: state.duplicatesIgnored + 1,
      );
      _syncDiagnostics(detectionAccuracy: detectionAccuracy);
      return;
    }

    _diagnostics.recordFrameReceived(payloadBytes: data.payload.length);
    final missing = _recon.totalChunks - _recon.receivedCount;
    _diagnostics.updateMissingCount(missing);

    state = state.copyWith(
      receivedChunks: _recon.receivedCount,
      progress: _recon.progress,
      missingChunks: missing,
    );
    _syncDiagnostics(detectionAccuracy: detectionAccuracy);

    if (!_recon.isComplete) {
      await _attemptFecRecovery();
    }

    if (_recon.isComplete) {
      await _finalize();
    }
  }

  void _handleParity(
    ParityPacket parity, {
    required double detectionAccuracy,
  }) {
    if (!_recon.hasMetadata) {
      _syncDiagnostics(detectionAccuracy: detectionAccuracy);
      return;
    }
    if (_fecRecovery.ingestParity(parity)) {
      _diagnostics.recordFrameReceived(payloadBytes: parity.payload.length);
    }
    _syncDiagnostics(detectionAccuracy: detectionAccuracy);
  }

  Future<void> _attemptFecRecovery() async {
    if (!_fecRecovery.config.enabled || !_recon.hasMetadata) return;

    final result = _fecRecovery.attemptRecovery(_recon);
    if (result.recoveredCount > 0) {
      _diagnostics.updateFecStatistics(_fecRecovery.statistics);
      ref.read(colorMatrixReceiverAdaptiveProvider)
          .updateFecStatistics(_fecRecovery.statistics);

      final missing = _recon.totalChunks - _recon.receivedCount;
      _diagnostics.updateMissingCount(missing);
      state = state.copyWith(
        receivedChunks: _recon.receivedCount,
        progress: _recon.progress,
        missingChunks: missing,
      );
    }
  }

  Future<void> _finalize() async {
    if (_finalizing) return;
    _finalizing = true;
    state = state.copyWith(phase: TransferPhase.reconstructing);

    await _attemptFecRecovery();

    try {
      final wireBytes = _recon.rebuild();
      final meta = _recon.metadata;
      if (wireBytes == null || meta == null) {
        throw StateError('Incomplete reconstruction');
      }
      if (wireBytes.length != meta.fileSize) {
        throw StateError('Reconstructed wire size mismatch');
      }
      if (!_core.sha256Verify(wireBytes, meta.sha256)) {
        throw StateError('Wire payload SHA-256 check failed');
      }

      final plaintext = await _pipeline.restore(
        wireBytes: wireBytes,
        meta: MetadataPacketFields(
          compression: meta.compression,
          encryption: meta.encryption,
          originalSize: meta.originalSize,
          originalSha256: meta.originalSha256,
        ),
        keyProvider: _keyProvider,
      );

      final expectedSize = meta.originalSize ?? meta.fileSize;
      final expectedHash = meta.originalSha256 ?? meta.sha256;
      if (plaintext.length != expectedSize) {
        throw StateError('Plaintext size mismatch after decompress');
      }
      if (!_core.sha256Verify(plaintext, expectedHash)) {
        throw StateError('Original file SHA-256 check failed');
      }

      final dir = await getApplicationDocumentsDirectory();
      final safeName = meta.fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
      final outputPath = '${dir.path}/$safeName';
      await File(outputPath).writeAsBytes(plaintext, flush: true);

      _keyProvider.clear();

      final adaptive = ref.read(colorMatrixReceiverAdaptiveProvider);
      await adaptive.finalizeSession();

      final elapsed = _receiveStartedAt != null
          ? DateTime.now().difference(_receiveStartedAt!).inMilliseconds
          : 0;

      if (_historyId != null) {
        await ref.read(historyRepositoryProvider).replaceRecord(
              TransferRecord(
                id: _historyId!,
                sessionId: meta.sessionId,
                fileName: meta.fileName,
                method: TransferMethod.colorMatrix,
                sizeBytes: expectedSize,
                status: TransferStatus.success,
                timestamp: DateTime.now(),
                direction: TransferDirection.received,
                durationMs: elapsed,
                compressionUsed: meta.compression != CompressionType.none,
                encryptionUsed: meta.encryption == EncryptionMode.enabled,
                transferSpeedBytesPerSec:
                    _diagnostics.current.throughputBytesPerSecond,
                avgQualityScore: adaptive.state.qualityScore.score,
                avgThroughput: _diagnostics.current.throughputBytesPerSecond,
                profileUsed: state.transportProfile.id,
                adaptiveEventCount:
                    adaptive.diagnostics.appliedDecisionCount,
                environmentSummary: adaptive.state.environment.summary,
                protocolVersion: 5,
                fecProfile: _fecRecovery.config.profile.id,
                packetsRecovered: _fecRecovery.statistics.packetsRecovered,
                recoveryRate: _fecRecovery.statistics.recoverySuccessRate,
                parityOverhead: _fecRecovery.statistics.fecOverhead,
              ),
            );
      }

      state = state.copyWith(
        phase: TransferPhase.completed,
        outputPath: outputPath,
        integrityValid: true,
        progress: 1.0,
        receivedChunks: meta.totalChunks,
        missingChunks: 0,
        qualityScore: adaptive.state.qualityScore,
      );
    } catch (e) {
      _keyProvider.clear();
      await _finalizeHistoryFailed(e.toString());
      state = state.copyWith(
        phase: TransferPhase.failed,
        errorMessage: e.toString(),
        integrityValid: false,
      );
    }
  }

  Future<void> _finalizeHistoryFailed(String reason) async {
    if (_historyId == null) return;
    final adaptive = ref.read(colorMatrixReceiverAdaptiveProvider);
    await adaptive.finalizeSession();
    final elapsed = _receiveStartedAt != null
        ? DateTime.now().difference(_receiveStartedAt!).inMilliseconds
        : 0;
    await ref.read(historyRepositoryProvider).replaceRecord(
          TransferRecord(
            id: _historyId!,
            sessionId: state.session?.id,
            fileName: state.session?.fileName ?? 'unknown',
            method: TransferMethod.colorMatrix,
            sizeBytes: state.session?.fileSize ?? 0,
            status: TransferStatus.failed,
            timestamp: DateTime.now(),
            direction: TransferDirection.received,
            durationMs: elapsed,
            failureReason: reason,
            avgQualityScore: adaptive.state.qualityScore.score,
            profileUsed: state.transportProfile.id,
            adaptiveEventCount: adaptive.diagnostics.appliedDecisionCount,
            environmentSummary: adaptive.state.environment.summary,
            protocolVersion: 4,
          ),
        );
  }

  void _syncAdaptiveState() {
    final adaptive = ref.read(colorMatrixReceiverAdaptiveProvider);
    ref.read(adaptiveStateProvider.notifier).state = adaptive.state;
    state = state.copyWith(
      adaptive: adaptive.state,
      qualityScore: adaptive.state.qualityScore,
      lighting: adaptive.state.lighting,
    );
  }

  void _syncDiagnostics({required double detectionAccuracy}) {
    state = state.copyWith(
      diagnostics: _diagnostics.current,
      detectionAccuracy: detectionAccuracy,
      missingChunks: _recon.hasMetadata
          ? _recon.totalChunks - _recon.receivedCount
          : state.missingChunks,
    );
  }

  int get processingThrottleMs =>
      state.adaptive.processingThrottleMs;

  void reset() {
    _recon.reset();
    _fecEngine.reset();
    _keyProvider.clear();
    _diagnostics.reset();
    _finalizing = false;
    _sessionTransport = null;
    ref.read(colorMatrixReceiverAdaptiveProvider).reset();
    state = const ColorMatrixReceiverState();
  }
}
