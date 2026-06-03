import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/application/history_controller.dart';
import '../../history/domain/transfer_record.dart';
import '../../protocols/interfaces/transfer_session.dart';
import '../../protocols/transfer_method.dart';
import '../core/integrity_verifier.dart';
import '../core/session_factory.dart';
import '../core/transfer_limits.dart';
import '../qr/qr_stream_controller.dart';
import 'transfer_providers.dart';
import 'transfer_state.dart';

/// Manages sender transfer lifecycle: prepare -> transmit QR frames.
class SenderController extends Notifier<SenderTransferState> {
  QrStreamController? _streamController;
  SenderSessionBundle? _bundle;

  @override
  SenderTransferState build() {
    ref.onDispose(() {
      _streamController?.dispose();
    });
    return const SenderTransferState();
  }

  SessionFactory get _sessionFactory => ref.read(sessionFactoryProvider);

  /// Reads file, builds session, and enters preparing state.
  Future<void> prepareTransfer({
    required String filePath,
    required String fileName,
    required String? extension,
  }) async {
    state = state.copyWith(
      phase: TransferPhase.preparing,
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
      final fileLength = await file.length();
      TransferLimits.validateFileSize(fileLength);

      final bytes = await file.readAsBytes();
      final mimeType = mimeTypeFromExtension(extension);

      _bundle = _sessionFactory.prepareSenderSession(
        fileBytes: Uint8List.fromList(bytes),
        fileName: fileName,
        mimeType: mimeType,
      );

      _streamController = QrStreamController();
      _streamController!.setPackets(_bundle!.allPackets);

      state = SenderTransferState(
        phase: TransferPhase.preparing,
        session: _bundle!.session.copyWith(
          state: TransferSessionState.preparing,
        ),
        totalFrames: _bundle!.allPackets.length,
        filePath: filePath,
      );
    } on TransferLimitException catch (e) {
      state = state.copyWith(
        phase: TransferPhase.failed,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        phase: TransferPhase.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Starts cyclic QR frame transmission.
  Future<void> startTransmission() async {
    if (_bundle == null || _streamController == null) return;

    final session = _bundle!.session;
    final historyId =
        '${session.id}-send-${DateTime.now().millisecondsSinceEpoch}';
    await ref.read(historyRepositoryProvider).addRecord(
          TransferRecord(
            id: historyId,
            fileName: session.fileName,
            method: TransferMethod.qr,
            sizeBytes: session.fileSize,
            status: TransferStatus.inProgress,
            timestamp: DateTime.now(),
            direction: TransferDirection.sent,
          ),
        );
    ref.invalidate(historyProvider);

    _streamController!.start(
      framesPerSecond: state.framesPerSecond,
      onFrame: (frameData, index, total) {
        state = state.copyWith(
          phase: TransferPhase.transmitting,
          currentFrameData: frameData,
          currentFrameIndex: index,
          totalFrames: total,
          loopCount: _streamController!.loopCount,
          session: _bundle!.session.copyWith(
            state: TransferSessionState.transmitting,
            progress: (index + 1) / total,
          ),
        );
      },
    );

    state = state.copyWith(
      phase: TransferPhase.transmitting,
      session: _bundle!.session.copyWith(
        state: TransferSessionState.transmitting,
      ),
      historyRecordId: historyId,
    );
  }

  void setFrameRate(double fps) {
    state = state.copyWith(framesPerSecond: fps);
    if (state.phase == TransferPhase.transmitting && _streamController != null) {
      _streamController!.stop();
      _streamController!.start(
        framesPerSecond: fps,
        onFrame: (frameData, index, total) {
          state = state.copyWith(
            currentFrameData: frameData,
            currentFrameIndex: index,
            totalFrames: total,
            loopCount: _streamController!.loopCount,
          );
        },
      );
    }
  }

  Future<void> stopTransmission() async {
    _streamController?.stop();
    await _updateHistoryStatus(TransferStatus.cancelled);
    state = state.copyWith(phase: TransferPhase.idle);
  }

  Future<void> _updateHistoryStatus(
    TransferStatus status, [
    String? recordId,
  ]) async {
    final id = recordId ?? state.historyRecordId;
    if (id == null) return;
    await ref.read(historyRepositoryProvider).updateStatus(id, status);
    ref.invalidate(historyProvider);
  }

  void reset() {
    final historyId = state.historyRecordId;
    final phase = state.phase;
    if (historyId != null &&
        (phase == TransferPhase.transmitting ||
            phase == TransferPhase.preparing)) {
      unawaited(_updateHistoryStatus(TransferStatus.cancelled, historyId));
    }
    _streamController?.dispose();
    _streamController = null;
    _bundle = null;
    state = const SenderTransferState();
  }
}
