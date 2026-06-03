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
import '../core/reconstruction_engine.dart';
import '../core/session_store.dart';
import '../core/transfer_limits.dart';
import '../qr/qr_frame_codec.dart';
import 'transfer_providers.dart';
import 'transfer_state.dart';

/// Manages receiver lifecycle: scan -> reconstruct -> verify -> save.
class ReceiverController extends Notifier<ReceiverTransferState> {
  ReconstructionEngine? _reconstruction;
  int _duplicatesIgnored = 0;
  bool _isFinalizing = false;

  @override
  ReceiverTransferState build() {
    return const ReceiverTransferState();
  }

  QrFrameCodec get _codec => ref.read(qrFrameCodecProvider);
  IntegrityVerifier get _verifier => ref.read(integrityVerifierProvider);
  SessionStore get _sessionStore => ref.read(sessionStoreProvider);

  void startReceiving() {
    _reconstruction = ReconstructionEngine();
    _duplicatesIgnored = 0;
    _isFinalizing = false;
    state = const ReceiverTransferState(phase: TransferPhase.receiving);
  }

  /// Processes a raw QR scan string.
  void onFrameScanned(String raw) {
    if (state.phase == TransferPhase.completed ||
        state.phase == TransferPhase.failed ||
        state.phase == TransferPhase.reconstructing ||
        _isFinalizing) {
      return;
    }

    final packet = _codec.decodeFrame(raw);
    if (packet == null) return;

    _reconstruction ??= ReconstructionEngine();

    if (packet is MetadataPacket) {
      if (_reconstruction!.hasMetadata &&
          _reconstruction!.metadata!.sessionId != packet.sessionId) {
        _reconstruction!.reset();
        _duplicatesIgnored = 0;
      }
    }

    final isNew = _reconstruction!.ingest(packet);
    if (!isNew) {
      _duplicatesIgnored++;
    }

    final metadata = _reconstruction!.metadata;
    if (metadata == null) return;

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
      duplicatesIgnored: _duplicatesIgnored,
    );

    unawaited(
      _sessionStore.save(
        SessionSnapshot(
          sessionId: metadata.sessionId,
          progress: _reconstruction!.progress,
          receivedChunkIds: _reconstruction!.receivedChunkIds.toList(),
          fileName: metadata.fileName,
          totalChunks: metadata.totalChunks,
          direction: 'receive',
        ),
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

    try {
      final metadata = _reconstruction?.metadata;
      if (metadata == null) {
        await _fail('Missing session metadata');
        return;
      }

      final rebuilt = _reconstruction!.rebuild();
      if (rebuilt == null) {
        await _fail('Failed to reconstruct file (incomplete or invalid chunks)');
        return;
      }

      if (rebuilt.length != metadata.fileSize) {
        await _fail('Reconstructed size does not match metadata');
        return;
      }

      final valid = _verifier.verify(rebuilt, metadata.sha256);
      if (!valid) {
        await _fail('SHA-256 integrity check failed');
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final safeName = metadata.fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
      final outputPath = '${dir.path}/$safeName';
      await File(outputPath).writeAsBytes(rebuilt);

      await _sessionStore.remove(metadata.sessionId);

      await ref.read(historyRepositoryProvider).addRecord(
            TransferRecord(
              id: '${metadata.sessionId}-${DateTime.now().millisecondsSinceEpoch}',
              fileName: metadata.fileName,
              method: TransferMethod.qr,
              sizeBytes: metadata.fileSize,
              status: TransferStatus.success,
              timestamp: DateTime.now(),
              direction: TransferDirection.received,
            ),
          );

      ref.invalidate(historyProvider);

      state = ReceiverTransferState(
        phase: TransferPhase.completed,
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
        duplicatesIgnored: _duplicatesIgnored,
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
              method: TransferMethod.qr,
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
    _duplicatesIgnored = 0;
    _isFinalizing = false;
    state = const ReceiverTransferState();
  }
}
