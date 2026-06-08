import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/application/history_controller.dart';
import '../../history/domain/transfer_record.dart';
import '../../protocols/interfaces/transfer_session.dart';
import '../../protocols/transport_registry.dart';
import '../../protocols/transfer_method.dart';
import '../../settings/application/settings_controller.dart' show settingsProvider;
import '../color_matrix/color_frame_generator.dart';
import '../color_matrix/color_matrix_frame.dart';
import '../core/frame_stream_controller.dart';
import '../core/integrity_verifier.dart';
import '../core/session_factory.dart';
import '../core/transfer_limits.dart';
import '../diagnostics/diagnostics_collector.dart';
import 'transfer_providers.dart';
import 'transfer_state.dart';

/// Manages sender transfer lifecycle: prepare -> transmit frames.
class SenderController extends FamilyNotifier<SenderTransferState, TransferMethod> {
  FrameStreamController<dynamic>? _streamController;
  SenderSessionBundle? _bundle;
  ColorFrameGenerator? _colorGenerator;
  DiagnosticsCollector? _diagnostics;

  @override
  SenderTransferState build(TransferMethod method) {
    ref.onDispose(() {
      _streamController?.dispose();
    });
    return SenderTransferState(
      method: method,
      framesPerSecond: ref.read(transportRegistryProvider).get(method).transport.capabilities.defaultFramesPerSecond,
    );
  }

  SessionFactory get _sessionFactory => ref.read(sessionFactoryProvider);
  DiagnosticsCollector get _diag {
    _diagnostics ??= ref.read(diagnosticsCollectorProvider);
    return _diagnostics!;
  }

  Future<void> prepareTransfer({
    required String filePath,
    required String fileName,
    required String? extension,
    String passphrase = '',
  }) async {
    final method = arg;
    final transport = ref.read(transportRegistryProvider).get(method).transport;
    final settings = ref.read(settingsProvider);

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
      if (fileLength > transport.capabilities.maxFileBytes) {
        throw TransferLimitException(
          'File exceeds ${transport.capabilities.maxFileBytes ~/ 1024} KB limit',
        );
      }

      final bytes = await file.readAsBytes();
      final mimeType = mimeTypeFromExtension(extension);

      _bundle = await _sessionFactory.prepareSenderSession(
        fileBytes: Uint8List.fromList(bytes),
        fileName: fileName,
        mimeType: mimeType,
        limits: transport.limits,
        encoder: transport.encoder,
        compressionEnabled: settings.compressionEnabled,
        encryptionEnabled: settings.encryptionEnabled,
        passphrase: passphrase,
      );

      _streamController = FrameStreamController(encoder: transport.encoder);
      _streamController!.setPackets(_bundle!.allPackets);

      if (method == TransferMethod.colorMatrix) {
        _colorGenerator = ColorFrameGenerator(
          showDebugOverlay: settings.debugOverlay,
        );
      }

      state = SenderTransferState(
        phase: TransferPhase.preparing,
        method: method,
        session: _bundle!.session.copyWith(
          state: TransferSessionState.preparing,
        ),
        totalFrames: _bundle!.allPackets.length,
        filePath: filePath,
        framesPerSecond: method == TransferMethod.colorMatrix
            ? settings.colorTransferFrameRate
            : state.framesPerSecond,
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

  Future<void> startTransmission() async {
    if (_bundle == null || _streamController == null) return;

    final session = _bundle!.session;
    final historyId =
        '${session.id}-send-${DateTime.now().millisecondsSinceEpoch}';
    await ref.read(historyRepositoryProvider).addRecord(
          TransferRecord(
            id: historyId,
            fileName: session.fileName,
            method: arg,
            sizeBytes: session.fileSize,
            status: TransferStatus.inProgress,
            timestamp: DateTime.now(),
            direction: TransferDirection.sent,
          ),
        );
    ref.invalidate(historyProvider);

    _diag.reset();

    _streamController!.start(
      framesPerSecond: state.framesPerSecond,
      onFrame: (frameData, index, total) {
        _diag.recordFrameGenerated();
        if (arg == TransferMethod.qr) {
          state = state.copyWith(
            phase: TransferPhase.transmitting,
            currentQrFrame: frameData as String,
            currentFrameIndex: index,
            totalFrames: total,
            loopCount: _streamController!.loopCount,
            diagnostics: _diag.current,
            session: _bundle!.session.copyWith(
              state: TransferSessionState.transmitting,
              progress: (index + 1) / total,
            ),
          );
        } else if (arg == TransferMethod.colorMatrix) {
          final frame = frameData as ColorMatrixFrame;
          final raster = _colorGenerator?.generateRaster(frame);
          state = state.copyWith(
            phase: TransferPhase.transmitting,
            currentColorMatrixRaster: raster,
            currentFrameIndex: index,
            totalFrames: total,
            loopCount: _streamController!.loopCount,
            diagnostics: _diag.current,
            session: _bundle!.session.copyWith(
              state: TransferSessionState.transmitting,
              progress: (index + 1) / total,
            ),
          );
        }
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
      unawaited(startTransmission());
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
    _colorGenerator = null;
    _diagnostics = null;
    state = SenderTransferState(method: arg);
  }
}
