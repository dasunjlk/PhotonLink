import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/application/history_controller.dart';
import '../../history/domain/transfer_record.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../protocols/transfer_method.dart';
import '../core/integrity_verifier.dart';
import '../core/session_factory.dart';
import '../core/transfer_limits.dart';
import '../persistence/session_persistence_manager_impl.dart';
import '../qr/qr_frame_codec.dart';
import '../qr/qr_stream_controller.dart';
import '../reliability/models/persisted_session.dart';
import 'reliable_transfer_context.dart';
import 'transfer_providers.dart';
import 'transfer_state.dart';

/// Round-based bidirectional QR sender with ACK/NAK recovery.
class SenderController extends Notifier<SenderTransferState> {
  QrStreamController? _stream;
  SenderSessionBundle? _bundle;
  late ReliableTransferContext _ctx;

  @override
  SenderTransferState build() {
    _ctx = ReliableTransferContext(role: TransferRole.sender);
    ref.onDispose(() => _stream?.dispose());
    return const SenderTransferState();
  }

  SessionFactory get _sessionFactory => ref.read(sessionFactoryProvider);
  QrFrameCodec get _codec => ref.read(qrFrameCodecProvider);
  SessionPersistenceManagerImpl get _persistence =>
      ref.read(sessionPersistenceManagerProvider);

  Future<void> prepareTransfer({
    required String filePath,
    required String fileName,
    required String? extension,
  }) async {
    _ctx.reset();
    _transition(TransferPhase.preparing);
    state = state.copyWith(
      errorMessage: null,
      filePath: filePath,
      historyRecordId: null,
    );

    try {
      if (!isSupportedExtension(extension)) {
        throw TransferLimitException(
          'Unsupported file type. Supported: txt, pdf, jpg, png, zip',
        );
      }
      final file = File(filePath);
      TransferLimits.validateFileSize(await file.length());
      final bytes = await file.readAsBytes();

      _bundle = _sessionFactory.prepareSenderSession(
        fileBytes: Uint8List.fromList(bytes),
        fileName: fileName,
        mimeType: mimeTypeFromExtension(extension),
      );
      _ctx.bindSession(_bundle!.metadata);
      _stream = QrStreamController();

      state = SenderTransferState(
        phase: TransferPhase.preparing,
        session: _bundle!.session,
        totalFrames: _bundle!.dataPackets.length,
        filePath: filePath,
        diagnostics: _ctx.diagnostics.snapshot,
      );
      _transition(TransferPhase.waitingForReceiver);
      await _persist();
    } on TransferLimitException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<void> startTransmission() async {
    if (_bundle == null || _stream == null) return;

    final historyId =
        '${_bundle!.session.id}-send-${DateTime.now().millisecondsSinceEpoch}';
    await ref.read(historyRepositoryProvider).addRecord(
          TransferRecord(
            id: historyId,
            sessionId: _bundle!.session.id,
            fileName: _bundle!.session.fileName,
            method: TransferMethod.qr,
            sizeBytes: _bundle!.session.fileSize,
            status: TransferStatus.inProgress,
            timestamp: DateTime.now(),
            direction: TransferDirection.sent,
          ),
        );
    ref.invalidate(historyProvider);

    state = state.copyWith(historyRecordId: historyId);
    _beginMetadataBroadcast();
  }

  void _beginMetadataBroadcast() {
    _stream!.setPackets([_bundle!.metadata]);
    _transition(TransferPhase.waitingForReceiver);
    _stream!.start(
      framesPerSecond: state.framesPerSecond,
      onFrame: (data, index, total) {
        state = state.copyWith(
          currentFrameData: data,
          currentFrameIndex: index,
          totalFrames: total,
        );
      },
    );
    _syncState();
  }

  /// Sender scans receiver handshake/NAK/ACK (bidirectional turn).
  void onFrameScanned(String raw) {
    if (_ctx.isFinalizing || state.phase.isTerminal) return;
    final packet = _codec.decodeFrame(raw);
    if (packet == null) return;

    switch (packet) {
      case HandshakePacket handshake:
        _handleHandshake(handshake);
      case NakPacket nak:
        _handleNak(nak);
      case AckPacket ack:
        _handleAck(ack);
      case ControlPacket control:
        _handleControl(control);
      default:
        break;
    }
  }

  void _handleHandshake(HandshakePacket handshake) {
    if (_bundle == null || handshake.sessionId != _bundle!.session.id) return;
    for (final id in handshake.receivedChunkIds) {
      _ctx.ackManager.recordAcknowledged(id);
    }
    _beginDataRound(
      missingOverride: _ctx.recovery.computeMissingIds(
        totalPackets: _bundle!.metadata.totalChunks,
        receivedIds: handshake.receivedChunkIds.toSet(),
      ),
    );
  }

  void _handleNak(NakPacket nak) {
    if (_bundle == null || nak.sessionId != _bundle!.session.id) return;
    if (state.phase != TransferPhase.awaitingAcknowledgements &&
        state.phase != TransferPhase.recoveringMissingPackets) {
      return;
    }
    for (final id in nak.missingPacketIds) {
      if (!_ctx.retryManager.canRetry(id)) continue;
      _ctx.retryManager.recordRetry(id);
      _ctx.diagnostics.recordRetry();
    }
    if (_ctx.retryManager.hasPermanentFailures) {
      _fail('Permanent failure: max retries exceeded');
      return;
    }
    _transition(TransferPhase.recoveringMissingPackets);
    _beginDataRound(missingOverride: nak.missingPacketIds.toSet());
  }

  void _handleAck(AckPacket ack) {
    if (_bundle == null || ack.sessionId != _bundle!.session.id) return;
    _ctx.ackManager.processAck(ack);
    if (_ctx.ackManager.allAcknowledged ||
        ack.packetIds.length >= _bundle!.metadata.totalChunks) {
      _completeSuccess();
    }
  }

  void _handleControl(ControlPacket control) {
    if (_bundle == null || control.sessionId != _bundle!.session.id) return;
    if (control.type == ControlType.complete) {
      _completeSuccess();
    } else if (control.type == ControlType.cancel) {
      _transition(TransferPhase.cancelled);
      _syncState();
    }
  }

  void _beginDataRound({Set<int>? missingOverride}) {
    if (_bundle == null || _stream == null) return;
    _stream!.clearStatusFrame();

    final missing = missingOverride ??
        _ctx.recovery.computeMissingIds(
          totalPackets: _bundle!.metadata.totalChunks,
          receivedIds: _ctx.ackManager.acknowledgedIds,
        );

    if (missing.isEmpty) {
      _showEndOfRoundAndAwaitAck();
      return;
    }

    final toSend = _ctx.packetsForIds(_bundle!.dataPackets, missing);
    final queue = <TransferPacket>[
      ...toSend,
      ControlPacket(
        sessionId: _bundle!.session.id,
        type: ControlType.endOfRound,
        timestamp: DateTime.now(),
      ),
    ];

    _ctx.roundNumber++;
    _transition(TransferPhase.transmitting);
    _stream!.setPackets(queue);
    _stream!.start(
      framesPerSecond: state.framesPerSecond,
      onFrame: (data, index, total) {
        if (index < toSend.length) {
          _ctx.diagnostics.recordSent();
        }
        state = state.copyWith(
          currentFrameData: data,
          currentFrameIndex: index,
          totalFrames: total,
          missingCount: missing.length,
          roundNumber: _ctx.roundNumber,
        );
      },
    );
    _syncState();
    unawaited(_persist());
  }

  void _showEndOfRoundAndAwaitAck() {
    if (_bundle == null || _stream == null) return;
    _stream!.showStatusFrame(
      ControlPacket(
        sessionId: _bundle!.session.id,
        type: ControlType.endOfRound,
        timestamp: DateTime.now(),
      ),
      framesPerSecond: state.framesPerSecond,
    );
    _transition(TransferPhase.awaitingAcknowledgements);
    state = state.copyWith(currentFrameData: _stream!.currentFrameData);
    _syncState();
  }

  /// Manual: sender finished data round, await receiver feedback.
  void finishRoundAndAwaitAck() {
    _stream?.stop();
    _showEndOfRoundAndAwaitAck();
  }

  /// Manual: start sending data after metadata (skip waiting for scan).
  void beginDataTransfer() => _beginDataRound();

  Future<void> _completeSuccess() async {
    if (_ctx.isFinalizing) return;
    _ctx.isFinalizing = true;
    _stream?.stop();
    _transition(TransferPhase.completed);
    _ctx.diagnostics.markCompleted();
    await _updateHistoryStatus(TransferStatus.success);
    if (_bundle != null) {
      await _persistence.remove(_bundle!.session.id);
    }
    state = state.copyWith(
      diagnostics: _ctx.diagnostics.snapshot,
      missingCount: 0,
    );
    _syncState();
  }

  void setFrameRate(double fps) {
    state = state.copyWith(framesPerSecond: fps);
    if (_stream?.isRunning ?? false) {
      _stream!.stop();
      _stream!.start(
        framesPerSecond: fps,
        onFrame: (data, index, total) {
          state = state.copyWith(
            currentFrameData: data,
            currentFrameIndex: index,
            totalFrames: total,
          );
        },
      );
    }
  }

  Future<void> stopTransmission() async {
    _stream?.stop();
    _transition(TransferPhase.cancelled);
    await _updateHistoryStatus(TransferStatus.cancelled);
    _syncState();
  }

  Future<void> pauseTransfer() async {
    _stream?.stop();
    _transition(TransferPhase.paused);
    await _persist();
    _syncState();
  }

  Future<void> resumeTransfer() async {
    if (_bundle == null) return;
    _transition(TransferPhase.resuming);
    _beginMetadataBroadcast();
  }

  Future<void> checkResumableSession() async {
    final session = await _persistence.findLatestResumable(
      role: TransferRole.sender,
    );
    if (session != null) {
      state = state.copyWith(resumableSession: session.sessionId);
    }
  }

  Future<void> restoreSession(String sessionId) async {
    final persisted = await _persistence.load(sessionId);
    if (persisted == null || persisted.senderFilePath == null) return;
    await prepareTransfer(
      filePath: persisted.senderFilePath!,
      fileName: persisted.fileName,
      extension: persisted.fileName.split('.').last,
    );
    _ctx.tracker.reset(
      sessionId: sessionId,
      totalPackets: persisted.totalChunks,
    );
    for (final id in persisted.receivedChunkIds) {
      _ctx.ackManager.recordAcknowledged(id);
    }
    _transition(TransferPhase.resuming);
    _beginDataRound();
  }

  Future<void> _persist() async {
    if (_bundle == null) return;
    final meta = _bundle!.metadata;
    await _persistence.save(
      PersistedSession(
        sessionId: meta.sessionId,
        role: TransferRole.sender,
        phase: _ctx.stateMachine.phase,
        fileName: meta.fileName,
        fileSize: meta.fileSize,
        totalChunks: meta.totalChunks,
        sha256: meta.sha256,
        mimeType: meta.mimeType,
        receivedChunkIds: _ctx.ackManager.acknowledgedIds.toList(),
        acknowledgedChunkIds: _ctx.ackManager.acknowledgedIds.toList(),
        progress: _ctx.ackManager.acknowledgedIds.length / meta.totalChunks,
        diagnostics: _ctx.diagnostics.snapshot,
        senderFilePath: state.filePath,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _transition(TransferPhase phase) {
    if (!_ctx.stateMachine.transition(phase)) {
      _ctx.stateMachine.forcePhase(phase);
    }
  }

  void _syncState() {
    state = state.copyWith(
      phase: _ctx.stateMachine.phase,
      diagnostics: _ctx.diagnostics.snapshot,
    );
  }

  void _fail(String message) {
    _ctx.diagnostics.markFailed(message);
    _transition(TransferPhase.failed);
    unawaited(_updateHistoryStatus(TransferStatus.failed));
    state = state.copyWith(
      phase: TransferPhase.failed,
      errorMessage: message,
      diagnostics: _ctx.diagnostics.snapshot,
    );
  }

  Future<void> _updateHistoryStatus(TransferStatus status) async {
    final id = state.historyRecordId;
    if (id == null) return;
    final diag = _ctx.diagnostics.snapshot;
    await ref.read(historyRepositoryProvider).updateRecord(
          id,
          status: status,
          retryCount: diag.retries,
          durationMs: diag.durationMs,
          failureReason: diag.failureReason,
        );
    ref.invalidate(historyProvider);
  }

  void reset() {
    final historyId = state.historyRecordId;
    final phase = state.phase;
    if (historyId != null &&
        (phase == TransferPhase.transmitting ||
            phase == TransferPhase.waitingForReceiver)) {
      unawaited(_updateHistoryStatus(TransferStatus.cancelled));
    }
    _stream?.dispose();
    _stream = null;
    _bundle = null;
    _ctx.reset();
    state = const SenderTransferState();
  }
}
