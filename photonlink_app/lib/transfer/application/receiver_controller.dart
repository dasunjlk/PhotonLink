import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../history/application/history_controller.dart';
import '../../history/domain/transfer_record.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../protocols/interfaces/transfer_session.dart';
import '../../protocols/transfer_method.dart';
import '../core/integrity_verifier.dart';
import '../core/transfer_limits.dart';
import '../persistence/session_persistence_manager_impl.dart';
import '../qr/qr_frame_codec.dart';
import '../qr/qr_stream_controller.dart';
import '../reliability/models/persisted_session.dart';
import 'reliable_transfer_context.dart';
import 'transfer_providers.dart';
import 'transfer_state.dart';

/// Round-based bidirectional QR receiver with ACK/NAK recovery.
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

  QrFrameCodec get _codec => ref.read(qrFrameCodecProvider);
  IntegrityVerifier get _verifier => ref.read(integrityVerifierProvider);
  SessionPersistenceManagerImpl get _persistence =>
      ref.read(sessionPersistenceManagerProvider);

  void startReceiving() {
    _ctx.reset();
    _statusStream = QrStreamController();
    _transition(TransferPhase.waitingForReceiver);
    _syncState(statusMessage: 'Scan sender metadata QR');
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
      case MetadataPacket metadata:
        _handleMetadata(metadata);
      case DataPacket data:
        _handleData(data);
      case ControlPacket control:
        _handleControl(control);
      default:
        break;
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
    _ctx.bindSession(metadata);
    _transition(TransferPhase.receiving);
    _syncState(statusMessage: 'Receiving data frames…');
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

    unawaited(_persist());

    if (_ctx.tracker.isComplete) {
      await _finalizeTransfer();
    }
  }

  void _handleControl(ControlPacket control) {
    if (_ctx.metadata == null ||
        control.sessionId != _ctx.metadata!.sessionId) {
      return;
    }
    if (control.type == ControlType.endOfRound) {
      _onEndOfRound();
    } else if (control.type == ControlType.pause) {
      _transition(TransferPhase.paused);
      _syncState(statusMessage: 'Transfer paused');
    }
  }

  void _onEndOfRound() {
    if (_ctx.metadata == null) return;
    if (_ctx.tracker.isComplete) {
      unawaited(_finalizeTransfer());
      return;
    }
    _showStatusToSender();
  }

  /// Display NAK or ACK QR for sender to scan.
  void showStatusToSender() => _showStatusToSender();

  void _showStatusToSender() {
    if (_ctx.metadata == null || _statusStream == null) return;

    TransferPacket status;
    String message;
    if (_ctx.tracker.isComplete) {
      status = _ctx.buildFullAck();
      message = 'Show ACK QR to sender';
      _transition(TransferPhase.awaitingAcknowledgements);
    } else {
      status = _ctx.buildNak();
      message = 'Show NAK QR (${_ctx.tracker.missingIds.length} missing)';
      _transition(TransferPhase.recoveringMissingPackets);
    }

    _statusStream!.showStatusFrame(
      status,
      framesPerSecond: 2,
    );
    state = state.copyWith(
      currentFrameData: _statusStream!.currentFrameData,
      statusMessage: message,
      missingCount: _ctx.tracker.missingIds.length,
      diagnostics: _ctx.diagnostics.snapshot,
    );
    _syncState(statusMessage: message);
  }

  /// Receiver shows handshake QR for sender to scan (resume).
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
      await _fail('Reconstructed size mismatch');
      return;
    }
    if (!_verifier.verify(rebuilt, metadata.sha256)) {
      await _fail('SHA-256 integrity check failed');
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeName =
          metadata.fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
      final outputPath = '${dir.path}/$safeName';
      await File(outputPath).writeAsBytes(rebuilt);

      await _ctx.chunkStore.removeSession(metadata.sessionId);
      await _persistence.remove(metadata.sessionId);

      _ctx.diagnostics.markCompleted();
      final diag = _ctx.diagnostics.snapshot;

      await ref.read(historyRepositoryProvider).addRecord(
            TransferRecord(
              id: '${metadata.sessionId}-rx-${DateTime.now().millisecondsSinceEpoch}',
              sessionId: metadata.sessionId,
              fileName: metadata.fileName,
              method: TransferMethod.qr,
              sizeBytes: metadata.fileSize,
              status: TransferStatus.success,
              timestamp: DateTime.now(),
              direction: TransferDirection.received,
              retryCount: diag.retries,
              durationMs: diag.durationMs,
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

      _transition(TransferPhase.completed);
      state = ReceiverTransferState(
        phase: TransferPhase.completed,
        session: TransferSession.fromMetadata(metadata).copyWith(
          state: TransferSessionState.completed,
          progress: 1,
        ),
        receivedChunks: metadata.totalChunks,
        totalChunks: metadata.totalChunks,
        progress: 1,
        outputPath: outputPath,
        integrityValid: true,
        duplicatesIgnored: _ctx.tracker.duplicateCount,
        diagnostics: diag,
        currentFrameData: _statusStream?.currentFrameData,
        statusMessage: 'Transfer complete — show to sender',
      );
    } catch (e) {
      await _fail('Failed to save file: $e');
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
              sizeBytes: metadata.fileSize,
              status: TransferStatus.failed,
              timestamp: DateTime.now(),
              direction: TransferDirection.received,
              failureReason: message,
              durationMs: _ctx.diagnostics.snapshot.durationMs,
            ),
          );
      ref.invalidate(historyProvider);
    }
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

  void _syncState({String? statusMessage}) {
    state = state.copyWith(
      phase: _ctx.stateMachine.phase,
      diagnostics: _ctx.diagnostics.snapshot,
      statusMessage: statusMessage,
    );
  }

  void reset() {
    _statusStream?.dispose();
    _statusStream = null;
    _ctx.reset();
    state = const ReceiverTransferState();
  }
}
