import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../history/application/history_controller.dart';
import '../../history/domain/transfer_record.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../protocols/interfaces/transfer_session.dart';
import '../../protocols/transport_registry.dart';
import '../../protocols/transfer_method.dart';
import '../color_matrix/color_matrix_frame.dart';
import '../core/integrity_verifier.dart';
import '../core/payload_pipeline.dart';
import '../core/reconstruction_engine.dart';
import '../core/transfer_limits.dart';
import '../diagnostics/diagnostics_collector.dart';
import '../reliability/missing_packet_tracker_impl.dart';
import '../reliability/retry_manager_impl.dart';
import '../reliability/transfer_recovery_manager_impl.dart';
import 'transfer_providers.dart';
import 'transfer_state.dart';

/// Manages receiver lifecycle: scan -> reconstruct -> verify -> save.
class ReceiverController
    extends FamilyNotifier<ReceiverTransferState, TransferMethod> {
  ReconstructionEngine? _reconstruction;
  MissingPacketTrackerImpl? _missingTracker;
  RetryManagerImpl? _retryManager;
  DiagnosticsCollector? _diagnostics;
  bool _isFinalizing = false;
  String _passphrase = '';

  @override
  ReceiverTransferState build(TransferMethod method) {
    return ReceiverTransferState(method: method);
  }

  IntegrityVerifier get _verifier => ref.read(integrityVerifierProvider);
  PayloadPipeline get _pipeline => ref.read(payloadPipelineProvider);
  DiagnosticsCollector get _diag {
    _diagnostics ??= ref.read(diagnosticsCollectorProvider);
    return _diagnostics!;
  }

  TransferRecoveryManagerImpl get _recovery =>
      ref.read(transferRecoveryManagerProvider);

  void startReceiving({String passphrase = ''}) {
    _passphrase = passphrase;
    _reconstruction = ReconstructionEngine();
    _missingTracker = MissingPacketTrackerImpl();
    _retryManager = RetryManagerImpl();
    _diag.reset();
    _isFinalizing = false;
    state = ReceiverTransferState(
      phase: TransferPhase.receiving,
      method: arg,
    );
  }

  /// Processes a raw QR scan string.
  void onQrFrameScanned(String raw) {
    final transport = ref.read(transportRegistryProvider).get(TransferMethod.qr).transport;
    final start = DateTime.now();
    final packet = transport.decoder.decodeFrame(raw);
    final elapsed = DateTime.now().difference(start);
    _diag.recordDecodeTime(elapsed);
    if (packet == null) {
      _diag.recordFrameCorrupted();
      state = state.copyWith(diagnostics: _diag.current);
      return;
    }
    _processPacket(packet, payloadBytes: packet is DataPacket ? packet.payload.length : 0);
  }

  /// Processes a decoded Color Matrix frame.
  void onColorMatrixFrame(ColorMatrixFrame frame, {double detectionAccuracy = 1.0}) {
    final transport =
        ref.read(transportRegistryProvider).get(TransferMethod.colorMatrix).transport;
    final start = DateTime.now();
    final packet = transport.decoder.decodeFrame(frame);
    final elapsed = DateTime.now().difference(start);
    _diag.recordDecodeTime(elapsed);
    _diag.recordDetectionAccuracy(detectionAccuracy);

    if (packet == null) {
      _diag.recordFrameCorrupted();
      state = state.copyWith(
        diagnostics: _diag.current,
        detectionAccuracy: detectionAccuracy,
      );
      return;
    }
    _processPacket(
      packet,
      payloadBytes: packet is DataPacket ? packet.payload.length : 0,
      detectionAccuracy: detectionAccuracy,
    );
  }

  void _processPacket(
    TransferPacket packet, {
    int payloadBytes = 0,
    double detectionAccuracy = 1.0,
  }) {
    if (state.phase == TransferPhase.completed ||
        state.phase == TransferPhase.failed ||
        state.phase == TransferPhase.reconstructing ||
        _isFinalizing) {
      return;
    }

    _reconstruction ??= ReconstructionEngine();
    _missingTracker ??= MissingPacketTrackerImpl();

    if (packet is MetadataPacket) {
      if (_reconstruction!.hasMetadata &&
          _reconstruction!.metadata!.sessionId != packet.sessionId) {
        _reconstruction!.reset();
        _missingTracker!.reset();
      }
      _missingTracker!.setTotalExpected(packet.totalChunks);
    }

    final isNew = _reconstruction!.ingest(packet);
    _diag.recordFrameReceived(payloadBytes: payloadBytes);
    if (!isNew) {
      _diag.recordDuplicate();
      _missingTracker!.onPacketReceived(
        packet is DataPacket ? packet.chunkId : 0,
        isNew: false,
      );
    } else if (packet is DataPacket) {
      _missingTracker!.onPacketReceived(packet.chunkId, isNew: true);
    }

    final metadata = _reconstruction!.metadata;
    if (metadata == null) return;

    final missing = _missingTracker!.missingPacketIds.length;
    _diag.updateMissingCount(missing);
    if (missing > 0) {
      _diag.recordFrameLost(missing);
    }

    final session = TransferSession.fromMetadata(metadata).copyWith(
      state: TransferSessionState.receiving,
      receivedChunks: _reconstruction!.receivedChunkIds,
      progress: _reconstruction!.progress,
    );

    state = state.copyWith(
      phase: TransferPhase.receiving,
      session: session,
      receivedChunks: _reconstruction!.receivedCount,
      totalChunks: metadata.totalChunks,
      progress: _reconstruction!.progress,
      duplicatesIgnored: _diag.current.duplicatesIgnored,
      diagnostics: _diag.current,
      detectionAccuracy: detectionAccuracy,
      missingChunks: missing,
    );

    unawaited(
      _recovery.persistProgress(
        sessionId: metadata.sessionId,
        receivedChunkIds: _reconstruction!.receivedChunkIds,
        metadata: metadata,
        direction: 'receive',
      ),
    );

    if (_reconstruction!.isComplete) {
      unawaited(_finalizeTransfer());
    }
  }

  Future<void> _finalizeTransfer() async {
    if (_isFinalizing) return;
    _isFinalizing = true;

    state = state.copyWith(phase: TransferPhase.reconstructing);

    const finalizeKey = 'finalize';
    try {
      final metadata = _reconstruction?.metadata;
      if (metadata == null) {
        await _fail('Missing session metadata');
        return;
      }

      final rebuilt = _reconstruction!.rebuild();
      if (rebuilt == null) {
        if (_retryManager!.shouldRetry(finalizeKey)) {
          _retryManager!.recordAttempt(finalizeKey);
          _diag.recordFrameRetried();
          _isFinalizing = false;
          return;
        }
        await _fail('Failed to reconstruct file (incomplete or invalid chunks)');
        return;
      }

      final transformed = await _pipeline.reverse(
        transformed: rebuilt,
        compression: metadata.compression,
        encryption: metadata.encryption,
        passphrase: _passphrase,
        kdfSalt: metadata.kdfSalt,
        encryptionNonce: metadata.encryptionNonce,
      );

      if (transformed.length != metadata.fileSize) {
        await _fail('Reconstructed size does not match metadata');
        return;
      }

      final valid = _verifier.verify(transformed, metadata.sha256);
      if (!valid) {
        await _fail('SHA-256 integrity check failed');
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final safeName = metadata.fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
      final outputPath = '${dir.path}/$safeName';
      await File(outputPath).writeAsBytes(transformed);

      await _recovery.clearSnapshot(metadata.sessionId);
      await _diag.persist(metadata.sessionId);

      await ref.read(historyRepositoryProvider).addRecord(
            TransferRecord(
              id: '${metadata.sessionId}-${DateTime.now().millisecondsSinceEpoch}',
              fileName: metadata.fileName,
              method: arg,
              sizeBytes: metadata.fileSize,
              status: TransferStatus.success,
              timestamp: DateTime.now(),
              direction: TransferDirection.received,
            ),
          );

      ref.invalidate(historyProvider);

      state = ReceiverTransferState(
        phase: TransferPhase.completed,
        method: arg,
        session: TransferSession.fromMetadata(metadata).copyWith(
          state: TransferSessionState.completed,
          progress: 1.0,
          completedAt: DateTime.now(),
        ),
        receivedChunks: metadata.totalChunks,
        totalChunks: metadata.totalChunks,
        progress: 1.0,
        outputPath: outputPath,
        integrityValid: true,
        duplicatesIgnored: _diag.current.duplicatesIgnored,
        diagnostics: _diag.current,
      );
    } on TransferLimitException catch (e) {
      await _fail(e.message);
    } catch (e) {
      await _fail('Failed to save file: $e');
    }
  }

  Future<void> _fail(String message) async {
    final metadata = _reconstruction?.metadata;
    if (metadata != null) {
      await ref.read(historyRepositoryProvider).addRecord(
            TransferRecord(
              id: '${metadata.sessionId}-fail-${DateTime.now().millisecondsSinceEpoch}',
              fileName: metadata.fileName,
              method: arg,
              sizeBytes: metadata.fileSize,
              status: TransferStatus.failed,
              timestamp: DateTime.now(),
              direction: TransferDirection.received,
            ),
          );
      ref.invalidate(historyProvider);
    }

    state = state.copyWith(
      phase: TransferPhase.failed,
      errorMessage: message,
      integrityValid: false,
    );
  }

  void reset() {
    _reconstruction?.reset();
    _reconstruction = null;
    _missingTracker = null;
    _retryManager = null;
    _diagnostics = null;
    _isFinalizing = false;
    state = ReceiverTransferState(method: arg);
  }
}
