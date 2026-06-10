import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../history/application/history_controller.dart';
import '../../history/domain/transfer_record.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../protocols/transfer_method.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/app_settings.dart';
import '../security/key_exchange.dart';
import '../core/integrity_verifier.dart';
import '../core/platform_file_reader.dart';
import '../core/payload_pipeline.dart';
import '../core/session_factory.dart';
import '../core/transfer_limits.dart';
import '../persistence/session_persistence_manager_impl.dart';
import '../qr/qr_frame_codec.dart';
import '../qr/qr_stream_controller.dart';
import '../reliability/models/persisted_session.dart';
import 'reliable_transfer_context.dart';
import 'transfer_providers.dart';
import 'transfer_state.dart';

/// Round-based bidirectional QR sender with ACK/NAK recovery + Phase 4 transforms.
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
  PayloadPipeline get _pipeline => ref.read(payloadPipelineProvider);
  QrFrameCodec get _codec => ref.read(qrFrameCodecProvider);
  SessionPersistenceManagerImpl get _persistence =>
      ref.read(sessionPersistenceManagerProvider);

  AppSettings get _settings => ref.read(settingsProvider);

  Future<void> prepareTransfer({
    required String fileName,
    required String? extension,
    String? filePath,
    Uint8List? fileBytes,
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
      final bytes = await loadFileBytes(
        fileBytes: fileBytes,
        filePath: filePath,
      );
      TransferLimits.validateFileSize(bytes.length);

      final compression = _settings.effectiveCompression;
      final encryption = _settings.encryptionEnabled
          ? EncryptionMode.enabled
          : EncryptionMode.disabled;

      KeyExchangeResult? keyResult;
      if (encryption == EncryptionMode.enabled) {
        keyResult = await _ctx.keyExchange.generateForSender();
        _ctx.keyProvider.setSessionKey(keyResult.sessionKey);
      }

      final prepared = await _pipeline.prepareForSend(
        fileBytes: bytes,
        compression: compression,
        encryption: encryption,
        keyProvider: _ctx.keyProvider,
      );

      _ctx.throughput.setCompressionRatio(prepared.compressionRatio);
      _ctx.throughput.addEncryptionOverhead(prepared.encryptionOverheadBytes);

      _bundle = _sessionFactory.prepareSenderSession(
        wireBytes: prepared.wireBytes,
        fileName: fileName,
        mimeType: mimeTypeFromExtension(extension),
        wireSha256: prepared.wireSha256,
        originalSize: prepared.originalSize,
        originalSha256: prepared.originalSha256,
        compression: prepared.compression,
        encryption: prepared.encryption,
      );

      SessionSetupPacket? setup;
      if (encryption == EncryptionMode.enabled && keyResult != null) {
        setup = SessionSetupPacket(
          sessionId: _bundle!.metadata.sessionId,
          protocolVersion: AppConstants.protocolVersion,
          keyExchangePayload: keyResult.payloadBase64,
          compression: compression,
          encryption: encryption,
          timestamp: DateTime.now(),
        );
      }

      _bundle = SenderSessionBundle(
        session: _bundle!.session,
        metadata: _bundle!.metadata,
        dataPackets: _bundle!.dataPackets,
        setupPacket: setup,
      );

      _ctx.setupPacket = setup;
      _ctx.bindSession(_bundle!.metadata);
      _ctx.diagnostics.setCompressionStats(
        savingsBytes: prepared.originalSize - prepared.wireBytes.length,
        ratio: prepared.compressionRatio,
      );
      _ctx.diagnostics.setEncryptionUsed(encryption == EncryptionMode.enabled);

      _stream = QrStreamController();
      final fps = _settings.transferMode.framesPerSecond;

      state = SenderTransferState(
        phase: TransferPhase.preparing,
        session: _bundle!.session,
        totalFrames: _bundle!.dataPackets.length,
        filePath: filePath,
        framesPerSecond: fps,
        diagnostics: _ctx.diagnostics.snapshot,
        compression: compression,
        encryption: encryption,
        compressionRatio: prepared.compressionRatio,
        compressionSavingsBytes:
            prepared.originalSize - prepared.wireBytes.length,
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
    final snap = _ctx.throughput.snapshot();
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
            compressionUsed: _bundle!.metadata.compression != CompressionType.none,
            encryptionUsed:
                _bundle!.metadata.encryption == EncryptionMode.enabled,
            compressionRatio: _bundle!.metadata.compression != CompressionType.none
                ? state.compressionRatio
                : null,
            transferSpeedBytesPerSec: snap.averageBytesPerSec,
            protocolVersion: _bundle!.metadata.protocolVersion,
          ),
        );
    ref.invalidate(historyProvider);

    state = state.copyWith(historyRecordId: historyId);
    _beginSetupAndMetadataBroadcast();
  }

  void _beginSetupAndMetadataBroadcast() {
    final packets = <TransferPacket>[];
    if (_bundle!.setupPacket != null) {
      packets.add(_bundle!.setupPacket!);
    }
    packets.add(_bundle!.metadata);
    _stream!.setPackets(packets);
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
    _ctx.diagnostics.recordAck();
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
    final mode = _settings.transferMode;
    final queue = _ctx.scheduler.buildDataRoundQueue(
      packetsToSend: toSend,
      sessionId: _bundle!.session.id,
    );

    _ctx.roundNumber++;
    _transition(TransferPhase.transmitting);
    _stream!.setPackets(queue);
    _stream!.start(
      framesPerSecond: mode.framesPerSecond,
      onFrame: (data, index, total) {
        if (index < toSend.length) {
          _ctx.diagnostics.recordSent();
          if (index < toSend.length) {
            _ctx.diagnostics.recordBytes(toSend[index].payload.length);
            _ctx.throughput.recordBytes(toSend[index].payload.length);
          }
        }
        state = state.copyWith(
          currentFrameData: data,
          currentFrameIndex: index,
          totalFrames: total,
          missingCount: missing.length,
          roundNumber: _ctx.roundNumber,
          framesPerSecond: mode.framesPerSecond,
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

  void finishRoundAndAwaitAck() {
    _stream?.stop();
    _showEndOfRoundAndAwaitAck();
  }

  void beginDataTransfer() => _beginDataRound();

  Future<void> _completeSuccess() async {
    if (_ctx.isFinalizing) return;
    _ctx.isFinalizing = true;
    _stream?.stop();
    _transition(TransferPhase.completed);
    _ctx.diagnostics.markCompleted();
    final snap = _ctx.throughput.snapshot();
    await _updateHistoryStatus(
      TransferStatus.success,
      transferSpeed: snap.averageBytesPerSec,
    );
    if (_bundle != null) {
      await _persistence.remove(_bundle!.session.id);
    }
    _ctx.keyProvider.clear();
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
    _ctx.keyProvider.clear();
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
    _beginSetupAndMetadataBroadcast();
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
    _ctx.keyProvider.clear();
    state = state.copyWith(
      phase: TransferPhase.failed,
      errorMessage: message,
      diagnostics: _ctx.diagnostics.snapshot,
    );
  }

  Future<void> _updateHistoryStatus(
    TransferStatus status, {
    double? transferSpeed,
  }) async {
    final id = state.historyRecordId;
    if (id == null) return;
    final diag = _ctx.diagnostics.snapshot;
    await ref.read(historyRepositoryProvider).updateRecord(
          id,
          status: status,
          retryCount: diag.retries,
          durationMs: diag.durationMs,
          failureReason: diag.failureReason,
          transferSpeedBytesPerSec: transferSpeed ?? diag.transferSpeedBytesPerSec,
          compressionRatio: state.compressionRatio,
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
