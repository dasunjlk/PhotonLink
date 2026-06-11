import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/application/history_controller.dart';
import '../../history/domain/transfer_record.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../protocols/transfer_method.dart';
import '../../settings/application/settings_controller.dart';
import '../adaptive/adaptive_engine_providers.dart';
import '../color_matrix/color_frame_generator.dart';
import '../color_matrix/color_matrix_frame.dart';
import '../color_matrix/color_matrix_frame_codec.dart';
import '../color_matrix/color_matrix_transfer_limits.dart';
import '../color_matrix/color_matrix_transport.dart';
import '../core/frame_stream_controller.dart';
import '../core/platform_file_reader.dart';
import '../core/integrity_verifier.dart';
import '../core/payload_pipeline.dart';
import '../core/session_factory.dart';
import '../core/transfer_limits.dart';
import '../diagnostics/diagnostics_collector.dart';
import '../security/encryption_key_provider.dart';
import '../security/session_key_exchange.dart';
import 'color_matrix_transfer_state.dart';
import 'transfer_providers.dart';

/// Cyclic Color Matrix sender using the Phase 4 payload pipeline.
class ColorMatrixSenderController extends Notifier<ColorMatrixSenderState> {
  FrameStreamController<ColorMatrixFrame>? _stream;
  SenderSessionBundle? _bundle;
  String? _keyExchangePayload;
  ColorMatrixTransport? _sessionTransport;
  final _keyProvider = EncryptionKeyProvider();
  final _keyExchange = SessionKeyExchange();
  late FrameDiagnosticsCollector _diagnostics;
  DateTime? _transferStartedAt;

  @override
  ColorMatrixSenderState build() {
    _diagnostics = ref.read(colorMatrixDiagnosticsCollectorProvider);
    ref.onDispose(() => _stream?.dispose());
    return ColorMatrixSenderState(
      framesPerSecond: ref.read(settingsProvider).colorTransferFrameRate,
    );
  }

  SessionFactory get _sessionFactory => ref.read(sessionFactoryProvider);
  PayloadPipeline get _pipeline => ref.read(payloadPipelineProvider);

  Future<void> prepareTransfer({
    required String fileName,
    required String? extension,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    _stream?.dispose();
    _stream = null;
    _bundle = null;
    _keyExchangePayload = null;
    _sessionTransport = null;
    _keyProvider.clear();
    _diagnostics.reset();
    _transferStartedAt = null;

    state = state.copyWith(
      phase: TransferPhase.preparing,
      errorMessage: null,
      filePath: filePath,
      currentColorMatrixRaster: null,
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
      TransferLimits.validateColorMatrixFileSize(bytes.length);

      final settings = ref.read(settingsProvider);
      final adaptive = ref.read(colorMatrixSenderAdaptiveProvider);
      await adaptive.initializeSession();
      final mapped = adaptive.getSessionStartParams();

      final compression = settings.effectiveCompression;
      final encryption = settings.encryptionEnabled
          ? EncryptionMode.enabled
          : EncryptionMode.disabled;

      if (encryption == EncryptionMode.enabled) {
        final keyResult = await _keyExchange.generateForSender();
        _keyProvider.setSessionKey(keyResult.sessionKey);
        _keyExchangePayload = keyResult.payloadBase64;
      }

      final prepared = await _pipeline.prepareForSend(
        fileBytes: bytes,
        compression: compression,
        encryption: encryption,
        keyProvider: _keyProvider,
      );

      final sessionId = _sessionFactory.generateSessionId();
      final preferredGrid = settings.adaptiveModeEnabled
          ? mapped.gridSize
          : settings.colorMatrixSize;
      final bitsPerChannel = settings.adaptiveModeEnabled
          ? mapped.bitsPerChannel
          : settings.colorBitsPerChannel;

      final viableGrid = ColorMatrixTransferLimits.resolveViableGrid(
        sessionId: sessionId,
        fileName: fileName,
        fileSize: prepared.wireBytes.length,
        bitsPerChannel: bitsPerChannel,
        compression: prepared.compression,
        encryption: prepared.encryption,
        originalSize: prepared.originalSize,
        originalSha256: prepared.originalSha256,
        keyExchangePayload: _keyExchangePayload,
        preferredGrid: preferredGrid,
      );

      final gridSize = viableGrid > preferredGrid ? viableGrid : preferredGrid;

      _sessionTransport = ColorMatrixTransport(
        gridSize: gridSize,
        bitsPerChannel: bitsPerChannel,
      );

      final codec = _sessionTransport!.encoder as ColorMatrixFrameCodec;
      final chunkSize = ColorMatrixTransferLimits.resolveChunkSize(
        sessionId: sessionId,
        fileBytes: prepared.wireBytes,
        chunkManager: ref.read(chunkingEngineProvider),
        encoder: codec,
        fileName: fileName,
        compression: prepared.compression,
        encryption: prepared.encryption,
        originalSize: prepared.originalSize,
        originalSha256: prepared.originalSha256,
        keyExchangePayload: _keyExchangePayload,
      );

      _bundle = _sessionFactory.prepareSenderSession(
        wireBytes: prepared.wireBytes,
        fileName: fileName,
        mimeType: mimeTypeFromExtension(extension),
        wireSha256: prepared.wireSha256,
        originalSize: prepared.originalSize,
        originalSha256: prepared.originalSha256,
        compression: prepared.compression,
        encryption: prepared.encryption,
        chunkSize: chunkSize,
        sessionIdOverride: sessionId,
        skipQrFrameValidation: true,
        maxFileBytes: TransferLimits.maxColorMatrixFileBytes,
      );

      if (!ColorMatrixTransferLimits.allFramesFit(
        sessionId: sessionId,
        metadata: _bundle!.metadata,
        dataPackets: _bundle!.dataPackets,
        encoder: codec,
      )) {
        throw TransferLimitException(
          'Encoded Color Matrix frames exceed grid capacity',
        );
      }

      state = ColorMatrixSenderState(
        phase: TransferPhase.waitingForReceiver,
        session: _bundle!.session,
        totalFrames: _bundle!.dataPackets.length + 1,
        filePath: filePath,
        framesPerSecond: mapped.framesPerSecond,
        compression: compression,
        encryption: encryption,
        diagnostics: _diagnostics.current,
        gridSize: gridSize,
        bitsPerChannel: bitsPerChannel,
        transportProfile: mapped.profile,
        qualityScore: adaptive.state.qualityScore,
      );
    } on TransferLimitException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<void> startTransmission() async {
    if (_bundle == null || _sessionTransport == null) return;

    final codec = _sessionTransport!.encoder as ColorMatrixFrameCodec;
    codec.encoderKeyExchangePayload = _keyExchangePayload;
    final generator = ColorFrameGenerator(
      showDebugOverlay: ref.read(settingsProvider).debugOverlay,
    );
    final adaptive = ref.read(colorMatrixSenderAdaptiveProvider);

    _stream = FrameStreamController<ColorMatrixFrame>(
      encoder: _sessionTransport!.encoder,
    );

    final packets = <TransferPacket>[
      _bundle!.metadata,
      ..._bundle!.dataPackets,
    ];
    _stream!.setPackets(packets);
    _transferStartedAt = DateTime.now();

    final historyId =
        '${_bundle!.session.id}-cm-send-${DateTime.now().millisecondsSinceEpoch}';
    await ref.read(historyRepositoryProvider).addRecord(
          TransferRecord(
            id: historyId,
            sessionId: _bundle!.session.id,
            fileName: _bundle!.session.fileName,
            method: TransferMethod.colorMatrix,
            sizeBytes: _bundle!.session.fileSize,
            status: TransferStatus.inProgress,
            timestamp: DateTime.now(),
            direction: TransferDirection.sent,
            compressionUsed:
                _bundle!.metadata.compression != CompressionType.none,
            encryptionUsed:
                _bundle!.metadata.encryption == EncryptionMode.enabled,
            profileUsed: state.transportProfile.id,
            protocolVersion: 4,
          ),
        );

    state = state.copyWith(
      phase: TransferPhase.transmitting,
      historyRecordId: historyId,
    );

    void onFrame(ColorMatrixFrame frame, int index, int total) {
      _diagnostics.recordFrameGenerated();
      final raster = generator.generateRaster(frame);
      final decision = adaptive.evaluateSenderFps(_diagnostics.current);
      final fps = decision.applied
          ? adaptive.state.mapped.framesPerSecond
          : state.framesPerSecond;
      if (decision.applied && _stream != null) {
        _stream!.setFrameRate(fps);
      }
      state = state.copyWith(
        currentFrameIndex: index,
        totalFrames: total,
        loopCount: _stream!.loopCount,
        currentColorMatrixRaster: raster,
        diagnostics: _diagnostics.current,
        framesPerSecond: fps,
        qualityScore: adaptive.state.qualityScore,
      );
    }

    _stream!.start(
      framesPerSecond: state.framesPerSecond,
      onFrame: onFrame,
    );
  }

  void setFrameRate(double fps) {
    _stream?.setFrameRate(fps);
    state = state.copyWith(framesPerSecond: fps);
  }

  Future<void> stopTransmission() async {
    _stream?.stop();
    await _finalizeHistory(TransferStatus.cancelled);
    state = state.copyWith(phase: TransferPhase.cancelled);
  }

  void reset() {
    _stream?.dispose();
    _stream = null;
    _bundle = null;
    _sessionTransport = null;
    _keyExchangePayload = null;
    _keyProvider.clear();
    _diagnostics.reset();
    ref.read(colorMatrixSenderAdaptiveProvider).reset();
    state = ColorMatrixSenderState(
      framesPerSecond: ref.read(settingsProvider).colorTransferFrameRate,
    );
  }

  Future<void> _finalizeHistory(TransferStatus status) async {
    final id = state.historyRecordId;
    if (id == null) return;
    final adaptive = ref.read(colorMatrixSenderAdaptiveProvider);
    await adaptive.finalizeSession();
    final elapsed = _transferStartedAt != null
        ? DateTime.now().difference(_transferStartedAt!).inMilliseconds
        : 0;
    await ref.read(historyRepositoryProvider).replaceRecord(
          TransferRecord(
            id: id,
            sessionId: state.session?.id,
            fileName: state.session?.fileName ?? 'unknown',
            method: TransferMethod.colorMatrix,
            sizeBytes: state.session?.fileSize ?? 0,
            status: status,
            timestamp: DateTime.now(),
            direction: TransferDirection.sent,
            durationMs: elapsed,
            compressionUsed: state.compression != CompressionType.none,
            encryptionUsed: state.encryption == EncryptionMode.enabled,
            transferSpeedBytesPerSec:
                state.diagnostics.throughputBytesPerSecond,
            avgQualityScore: adaptive.state.qualityScore.score,
            avgThroughput: state.diagnostics.throughputBytesPerSecond,
            profileUsed: state.transportProfile.id,
            adaptiveEventCount: adaptive.diagnostics.appliedDecisionCount,
            environmentSummary: adaptive.state.environment.summary,
            protocolVersion: 4,
          ),
        );
  }

  void _fail(String message) {
    state = state.copyWith(
      phase: TransferPhase.failed,
      errorMessage: message,
    );
    unawaited(_finalizeHistory(TransferStatus.failed));
  }
}
