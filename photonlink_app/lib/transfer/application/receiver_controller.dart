import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../../history/application/history_controller.dart';
import '../../history/domain/transfer_record.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../protocols/interfaces/transfer_session.dart';
import '../../protocols/transfer_method.dart';
import '../core/integrity_verifier.dart';
import '../core/payload_pipeline.dart';
import '../core/transfer_limits.dart';
import '../persistence/session_persistence_manager_impl.dart';
import '../qr/qr_frame_codec.dart';
import '../qr/qr_stream_controller.dart';
import '../reliability/models/persisted_session.dart';
import 'reliable_transfer_context.dart';
import 'transfer_providers.dart';
import 'transfer_state.dart';

/// Round-based bidirectional QR receiver with ACK/NAK + Phase 4 transforms.
class ReceiverController extends Notifier<ReceiverTransferState> {
  late ReliableTransferContext _ctx;
  QrStreamController? _statusStream;
  DateTime _lastScan = DateTime.fromMillisecondsSinceEpoch(0);
  static const _scanThrottleMs = 50;

  @override
  ReceiverTransferState build() {
    _ctx = ReliableTransferContext(role: TransferRole.receiver);
    ref.onDispose(() => _statusStream?.dispose());
    return const ReceiverTransferState();
  }

  PayloadPipeline get _pipeline => ref.read(payloadPipelineProvider);
  QrFrameCodec get _codec => ref.read(qrFrameCodecProvider);
  IntegrityVerifier get _verifier => ref.read(integrityVerifierProvider);
  SessionPersistenceManagerImpl get _persistence =>
      ref.read(sessionPersistenceManagerProvider);

  void startReceiving() {
    _ctx.reset();
    _statusStream = QrStreamController();
    _transition(TransferPhase.waitingForReceiver);
    _syncState(statusMessage: 'Scan sender setup or metadata QR');
  }

  void onFrameScanned(String raw) {
    if (_ctx.isFinalizing || state.phase.isTerminal) return;
    if (state.phase == TransferPhase.reconstructing) return;

    final now = DateTime.now();
    if (now.difference(_lastScan).inMilliseconds < _scanThrottleMs) return;
    _lastScan = now;

    final packet = _codec.decodeFrame(raw);
    if (packet == null) return;

    switch (packet) {
      case SessionSetupPacket setup:
        unawaited(_handleSetup(setup));
      case MetadataPacket metadata:
        _handleMetadata(metadata);
      case DataPacket data:
        unawaited(_handleData(data));
      case ControlPacket control:
        _handleControl(control);
      default:
        break;
    }
  }

  Future<void> _handleSetup(SessionSetupPacket setup) async {
    try {
      if (setup.encryption == EncryptionMode.enabled) {
        final key = await _ctx.keyExchange.acceptFromReceiver(
          setup.keyExchangePayload,
        );
        _ctx.keyProvider.setSessionKey(key);
      }
      _ctx.setupPacket = setup;
      state = state.copyWith(
        compression: setup.compression,
        encryption: setup.encryption,
        statusMessage: 'Session key received — scan metadata',
      );
    } catch (e) {
      state = state.copyWith(
        statusMessage: 'Invalid setup packet: $e',
      );
    }
  }

  void _handleMetadata(MetadataPacket metadata) {
    try {
      TransferLimits.validateMetadata(
        fileName: metadata.fileName,
        fileSize: metadata.fileSize,
        totalChunks: metadata.totalChunks,
        sha256: metadata.sha256,
      );
    } catch (_) {
      return;
    }
    if (metadata.encryption == EncryptionMode.enabled &&
        !_ctx.keyProvider.hasKey) {
      state = state.copyWith(
        statusMessage: 'Scan session setup QR first (encryption enabled)',
      );
      return;
    }
    _ctx.bindSession(metadata);
    _transition(TransferPhase.receiving);
    final savings = (metadata.originalSize ?? metadata.fileSize) -
        metadata.fileSize;
    _ctx.diagnostics.setCompressionStats(
      savingsBytes: savings > 0 ? savings : 0,
      ratio: metadata.originalSize != null && metadata.originalSize! > 0
          ? metadata.fileSize / metadata.originalSize!
          : 1,
    );
    _syncState(
      statusMessage: 'Receiving data frames…',
      compression: metadata.compression,
      encryption: metadata.encryption,
      compressionRatio: metadata.originalSize != null && metadata.originalSize! > 0
          ? metadata.fileSize / metadata.originalSize!
          : 1,
      compressionSavingsBytes: savings > 0 ? savings : 0,
    );
    unawaited(_persist());
  }

  Future<void> _handleData(DataPacket data) async {
    if (_ctx.metadata == null) return;
    if (data.sessionId != _ctx.metadata!.sessionId) return;
    if (state.phase != TransferPhase.receiving &&
        state.phase != TransferPhase.recoveringMissingPackets) {
      return;
    }

    final isNew = _ctx.tracker.recordReceived(data.chunkId);
    if (!isNew) {
      _ctx.diagnostics.recordDuplicate();
    } else {
      _ctx.diagnostics.recordReceived();
      _ctx.diagnostics.recordBytes(data.payload.length);
      _ctx.throughput.recordBytes(data.payload.length);
      await _ctx.chunkStore.saveChunk(
        sessionId: data.sessionId,
        chunkId: data.chunkId,
        payload: data.payload,
      );
      _ctx.reconstruction.ingest(data);
    }

    _ctx.diagnostics.updateProgress(_ctx.tracker.progress);
    _ctx.diagnostics.recordMissing(_ctx.tracker.missingIds.length);

    state = state.copyWith(
      session: TransferSession.fromMetadata(_ctx.metadata!),
      receivedChunks: _ctx.tracker.acceptedCount,
      totalChunks: _ctx.metadata!.totalChunks,
      progress: _ctx.tracker.progress,
      duplicatesIgnored: _ctx.tracker.duplicateCount,
      diagnostics: _ctx.diagnostics.snapshot,
      missingCount: _ctx.tracker.missingIds.length,
    );
  }

  void _handleControl(ControlPacket control) {
    if (_ctx.metadata == null) return;
    if (control.sessionId != _ctx.metadata!.sessionId) return;
    if (control.type == ControlType.endOfRound) {
      unawaited(_showStatusToSender());
    }
  }

  Future<void> _showStatusToSender() async {
    if (_ctx.metadata == null || _statusStream == null) return;
    if (_ctx.tracker.isComplete) {
      await _finalizeTransfer();
      return;
    }
    final nak = _ctx.buildNak();
    _statusStream!.showStatusFrame(nak);
    _transition(TransferPhase.awaitingAcknowledgements);
    state = state.copyWith(
      currentFrameData: _statusStream!.currentFrameData,
      statusMessage: 'Show NAK QR to sender (${_ctx.tracker.missingIds.length} missing)',
    );
  }

  void showStatusToSender() => unawaited(_showStatusToSender());

  void showHandshakeToSender() {
    if (_ctx.metadata == null || _statusStream == null) return;
    final hs = _ctx.buildHandshake();
    _statusStream!.showStatusFrame(hs);
    _transition(TransferPhase.awaitingAcknowledgements);
    state = state.copyWith(
      currentFrameData: _statusStream!.currentFrameData,
      statusMessage: 'Show handshake QR to sender',
    );
  }

  Future<void> _finalizeTransfer() async {
    if (_ctx.isFinalizing) return;
    _ctx.isFinalizing = true;
    _transition(TransferPhase.reconstructing);
    _syncState(statusMessage: 'Reconstructing file…');

    final metadata = _ctx.metadata!;
    _ctx.reconstruction.reset();
    _ctx.reconstruction.ingest(metadata);
    for (final id in _ctx.tracker.receivedIds) {
      final chunk = await _ctx.chunkStore.loadChunk(
        sessionId: metadata.sessionId,
        chunkId: id,
      );
      if (chunk != null) {
        _ctx.reconstruction.ingest(
          DataPacket(
            sessionId: metadata.sessionId,
            chunkId: id,
            totalChunks: metadata.totalChunks,
            payload: chunk,
          ),
        );
      }
    }

    final rebuilt = _ctx.reconstruction.rebuild();
    if (rebuilt == null) {
      await _fail('Failed to reconstruct file');
      return;
    }
    if (rebuilt.length != metadata.fileSize) {
      await _fail('Reconstructed wire size mismatch');
      return;
    }
    if (!_verifier.verify(rebuilt, metadata.sha256)) {
      await _fail('Wire payload SHA-256 check failed');
      return;
    }

    try {
      final plain = await _pipeline.restorePlaintext(
        wireBytes: rebuilt,
        meta: MetadataPacketFields(
          compression: metadata.compression,
          encryption: metadata.encryption,
          originalSize: metadata.originalSize,
          originalSha256: metadata.originalSha256,
        ),
        keyProvider: _ctx.keyProvider,
      );

      final expectedSize = metadata.originalSize ?? metadata.fileSize;
      final expectedHash =
          metadata.originalSha256 ?? metadata.sha256;
      if (plain.length != expectedSize) {
        await _fail('Plaintext size mismatch after decompress');
        return;
      }
      if (!_verifier.verify(plain, expectedHash)) {
        await _fail('Original file SHA-256 check failed');
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final safeName =
          metadata.fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
      final outputPath = '${dir.path}/$safeName';
      await File(outputPath).writeAsBytes(plain);

      await _ctx.chunkStore.removeSession(metadata.sessionId);
      await _persistence.remove(metadata.sessionId);

      _ctx.diagnostics.markCompleted();
      final diag = _ctx.diagnostics.snapshot;
      final snap = _ctx.throughput.snapshot();

      await ref.read(historyRepositoryProvider).addRecord(
            TransferRecord(
              id: '${metadata.sessionId}-rx-${DateTime.now().millisecondsSinceEpoch}',
              sessionId: metadata.sessionId,
              fileName: metadata.fileName,
              method: TransferMethod.qr,
              sizeBytes: expectedSize,
              status: TransferStatus.success,
              timestamp: DateTime.now(),
              direction: TransferDirection.received,
              retryCount: diag.retries,
              durationMs: diag.durationMs,
              compressionUsed:
                  metadata.compression != CompressionType.none,
              encryptionUsed:
                  metadata.encryption == EncryptionMode.enabled,
              compressionRatio: state.compressionRatio,
              transferSpeedBytesPerSec: snap.averageBytesPerSec,
              protocolVersion: metadata.protocolVersion,
            ),
          );
      ref.invalidate(historyProvider);

      _statusStream?.showStatusFrame(
        ControlPacket(
          sessionId: metadata.sessionId,
          type: ControlType.complete,
          timestamp: DateTime.now(),
        ),
      );

      _ctx.keyProvider.clear();
      _transition(TransferPhase.completed);
      state = ReceiverTransferState(
        phase: TransferPhase.completed,
        session: TransferSession.fromMetadata(metadata).copyWith(
          state: TransferSessionState.completed,
          progress: 1,
          fileSize: expectedSize,
        ),
        receivedChunks: metadata.totalChunks,
        totalChunks: metadata.totalChunks,
        progress: 1,
        outputPath: outputPath,
        integrityValid: true,
        duplicatesIgnored: _ctx.tracker.duplicateCount,
        diagnostics: diag,
        compression: metadata.compression,
        encryption: metadata.encryption,
        compressionRatio: state.compressionRatio,
        compressionSavingsBytes: state.compressionSavingsBytes,
        currentFrameData: _statusStream?.currentFrameData,
        statusMessage: 'Transfer complete — show to sender',
      );
    } catch (e) {
      await _fail('Failed to restore file: $e');
    }
  }

  Future<void> _fail(String message) async {
    _ctx.diagnostics.markFailed(message);
    final metadata = _ctx.metadata;
    if (metadata != null) {
      await ref.read(historyRepositoryProvider).addRecord(
            TransferRecord(
              id: '${metadata.sessionId}-fail-${DateTime.now().millisecondsSinceEpoch}',
              sessionId: metadata.sessionId,
              fileName: metadata.fileName,
              method: TransferMethod.qr,
              sizeBytes: metadata.originalSize ?? metadata.fileSize,
              status: TransferStatus.failed,
              timestamp: DateTime.now(),
              direction: TransferDirection.received,
              failureReason: message,
              durationMs: _ctx.diagnostics.snapshot.durationMs,
              protocolVersion: metadata.protocolVersion,
            ),
          );
      ref.invalidate(historyProvider);
    }
    _ctx.keyProvider.clear();
    _transition(TransferPhase.failed);
    state = state.copyWith(
      phase: TransferPhase.failed,
      errorMessage: message,
      integrityValid: false,
      diagnostics: _ctx.diagnostics.snapshot,
    );
  }

  Future<void> pauseTransfer() async {
    _statusStream?.stop();
    _transition(TransferPhase.paused);
    await _persist();
    _syncState(statusMessage: 'Paused');
  }

  Future<void> resumeTransfer() async {
    if (_ctx.metadata == null) return;
    _transition(TransferPhase.resuming);
    final ids = await _ctx.chunkStore.listChunkIds(_ctx.metadata!.sessionId);
    _ctx.tracker.reset(
      sessionId: _ctx.metadata!.sessionId,
      totalPackets: _ctx.metadata!.totalChunks,
    );
    for (final id in ids) {
      _ctx.tracker.recordReceived(id);
    }
    _transition(TransferPhase.receiving);
    _syncState(statusMessage: 'Resumed — scan data frames');
  }

  Future<void> checkResumableSession() async {
    final session = await _persistence.findLatestResumable(
      role: TransferRole.receiver,
    );
    if (session != null) {
      state = state.copyWith(resumableSession: session.sessionId);
    }
  }

  Future<void> restoreSession(String sessionId) async {
    final persisted = await _persistence.load(sessionId);
    if (persisted == null) return;

    final meta = MetadataPacket(
      sessionId: persisted.sessionId,
      fileName: persisted.fileName,
      fileSize: persisted.fileSize,
      totalChunks: persisted.totalChunks,
      sha256: persisted.sha256,
      mimeType: persisted.mimeType,
      protocolVersion: AppConstants.protocolVersion,
    );
    _ctx.bindSession(meta);
    for (final id in persisted.receivedChunkIds) {
      _ctx.tracker.recordReceived(id);
    }
    _transition(TransferPhase.resuming);
    state = state.copyWith(
      session: TransferSession.fromMetadata(meta),
      receivedChunks: _ctx.tracker.acceptedCount,
      totalChunks: meta.totalChunks,
      progress: _ctx.tracker.progress,
      diagnostics: persisted.diagnostics,
    );
    showHandshakeToSender();
  }

  Future<void> _persist() async {
    if (_ctx.metadata == null) return;
    final meta = _ctx.metadata!;
    await _persistence.save(
      PersistedSession(
        sessionId: meta.sessionId,
        role: TransferRole.receiver,
        phase: _ctx.stateMachine.phase,
        fileName: meta.fileName,
        fileSize: meta.fileSize,
        totalChunks: meta.totalChunks,
        sha256: meta.sha256,
        mimeType: meta.mimeType,
        receivedChunkIds: _ctx.tracker.receivedIds.toList(),
        acknowledgedChunkIds: [],
        progress: _ctx.tracker.progress,
        diagnostics: _ctx.diagnostics.snapshot,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _transition(TransferPhase phase) {
    if (!_ctx.stateMachine.transition(phase)) {
      _ctx.stateMachine.forcePhase(phase);
    }
  }

  void _syncState({
    String? statusMessage,
    CompressionType? compression,
    EncryptionMode? encryption,
    double? compressionRatio,
    int? compressionSavingsBytes,
  }) {
    state = state.copyWith(
      phase: _ctx.stateMachine.phase,
      diagnostics: _ctx.diagnostics.snapshot,
      statusMessage: statusMessage,
      compression: compression,
      encryption: encryption,
      compressionRatio: compressionRatio,
      compressionSavingsBytes: compressionSavingsBytes,
    );
  }

  void reset() {
    _statusStream?.dispose();
    _statusStream = null;
    _ctx.reset();
    state = const ReceiverTransferState();
  }
}
