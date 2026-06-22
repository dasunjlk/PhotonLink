import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/protocol_versions.dart';
import '../../history/application/history_controller.dart';
import '../../services/core/core_providers.dart';
import '../../history/domain/transfer_record.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../protocols/transfer_method.dart';
import '../../settings/application/settings_controller.dart';
import '../adaptive/adaptive_engine_providers.dart';
import '../optical_stream/optical_renderer.dart';
import '../optical_stream/optical_stream_encoder.dart';
import '../optical_stream/optical_stream_frame.dart';
import '../optical_stream/optical_stream_codec.dart';
import '../optical_stream/optical_stream_transfer_limits.dart';
import '../optical_stream/optical_stream_transport.dart';
import '../core/integrity_verifier.dart';
import '../core/platform_file_reader.dart';
import '../core/payload_pipeline.dart';
import '../core/session_factory.dart';
import '../core/transfer_limits.dart';
import '../fec/fec_configuration_factory.dart';
import '../fec/recovery_engine.dart';
import '../../services/core/fec_service.dart';
import '../../services/core/impl/dart_fec_service.dart';
import '../diagnostics/diagnostics_collector.dart';
import '../security/encryption_key_provider.dart';
import '../security/session_key_exchange.dart';
import 'optical_stream_transfer_state.dart';
import 'transfer_providers.dart';

/// Continuous Optical Stream sender using the payload pipeline.
class OpticalStreamSenderController extends Notifier<OpticalStreamSenderState> {
  OpticalStreamEncoder? _encoder;
  SenderSessionBundle? _bundle;
  String? _keyExchangePayload;
  OpticalStreamTransport? _sessionTransport;
  final _keyProvider = EncryptionKeyProvider();
  final _keyExchange = SessionKeyExchange();
  late FrameDiagnosticsCollector _diagnostics;
  final _fecEngine = RecoveryEngine();
  FecService get _fecRecovery => DartFecService(engine: _fecEngine);
  final _fecFactory = const FecConfigurationFactory();
  DateTime? _transferStartedAt;

  @override
  OpticalStreamSenderState build() {
    _diagnostics = ref.read(opticalStreamDiagnosticsCollectorProvider);
    ref.onDispose(() => _encoder?.dispose());
    return OpticalStreamSenderState(
      framesPerSecond: ref.read(settingsProvider).opticalStreamSpeed,
      frameRate: ref.read(settingsProvider).opticalStreamSpeed,
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
    _encoder?.dispose();
    _encoder = null;
    _bundle = null;
    _keyExchangePayload = null;
    _sessionTransport = null;
    _keyProvider.clear();
    _diagnostics.reset();
    _fecEngine.reset();
    _transferStartedAt = null;

    state = state.copyWith(
      phase: TransferPhase.preparing,
      errorMessage: null,
      filePath: filePath,
      currentOpticalRaster: null,
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
      TransferLimits.validateOpticalStreamFileSize(bytes.length);

      final settings = ref.read(settingsProvider);
      _fecRecovery.configure(_fecFactory.fromSettings(settings));
      final adaptive = ref.read(opticalStreamSenderAdaptiveProvider);
      await adaptive.initializeSession();
      final mapped = adaptive.getSessionStartParams();

      final compression = settings.effectiveCompression;
      final encryption = settings.encryptionEnabled
          ? EncryptionMode.enabled
          : EncryptionMode.disabled;

      final sessionId = _sessionFactory.generateSessionId();

      if (encryption == EncryptionMode.enabled) {
        final keyResult = await _keyExchange.generateForSender(
          sessionId: sessionId,
        );
        _keyProvider.setSessionKey(keyResult.sessionKey);
        _keyExchangePayload = keyResult.payloadBase64;
      }

      final prepared = await _pipeline.prepare(
        fileBytes: bytes,
        compression: compression,
        encryption: encryption,
        keyProvider: _keyProvider,
      );

      final preferredGrid = settings.adaptiveModeEnabled
          ? mapped.gridSize
          : settings.opticalStreamDensity;
      const bitsPerCell = 3;

      final viableGrid = OpticalStreamTransferLimits.resolveViableGrid(
        sessionId: sessionId,
        fileName: fileName,
        fileSize: prepared.wireBytes.length,
        bitsPerCell: bitsPerCell,
        compression: prepared.compression,
        encryption: prepared.encryption,
        originalSize: prepared.originalSize,
        originalSha256: prepared.originalSha256,
        keyExchangePayload: _keyExchangePayload,
        preferredGrid: preferredGrid,
      );

      final gridSize = viableGrid > preferredGrid ? viableGrid : preferredGrid;

      _sessionTransport = OpticalStreamTransport(
        gridSize: gridSize,
        bitsPerCell: bitsPerCell,
        codec: OpticalStreamFrameCodec(
          gridSize: gridSize,
          bitsPerCell: bitsPerCell,
          packetService: ref.read(packetServiceProvider),
        ),
      );

      final codec = _sessionTransport!.encoder as OpticalStreamFrameCodec;
      final chunkSize = OpticalStreamTransferLimits.resolveChunkSize(
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
        maxFileBytes: TransferLimits.maxOpticalStreamFileBytes,
      );

      if (!OpticalStreamTransferLimits.allFramesFit(
        sessionId: sessionId,
        metadata: _bundle!.metadata,
        dataPackets: _bundle!.dataPackets,
        encoder: codec,
      )) {
        throw TransferLimitException(
          'Encoded Optical Stream frames exceed grid capacity',
        );
      }

      final fps = settings.adaptiveModeEnabled
          ? mapped.framesPerSecond
          : settings.opticalStreamSpeed;

      state = OpticalStreamSenderState(
        phase: TransferPhase.waitingForReceiver,
        session: _bundle!.session,
        totalFrames: _bundle!.dataPackets.length + 1,
        filePath: filePath,
        framesPerSecond: fps,
        frameRate: fps,
        compression: compression,
        encryption: encryption,
        diagnostics: _diagnostics.current,
        gridSize: gridSize,
        bitsPerCell: bitsPerCell,
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

    final codec = _sessionTransport!.encoder as OpticalStreamFrameCodec;
    codec.encoderKeyExchangePayload = _keyExchangePayload;
    final renderer = OpticalRenderer(
      showDebugOverlay: ref.read(settingsProvider).opticalStreamDiagnostics,
    );
    final adaptive = ref.read(opticalStreamSenderAdaptiveProvider);

    _encoder = OpticalStreamEncoder(
      encoder: _sessionTransport!.encoder,
      framesPerSecond: state.framesPerSecond,
    );

    final packets = <TransferPacket>[
      _bundle!.metadata,
      ..._bundle!.dataPackets,
    ];
    if (_fecRecovery.config.enabled) {
      packets.addAll(
        _fecRecovery.generateParity(
          dataPackets: _bundle!.dataPackets,
          sessionId: _bundle!.session.id,
          totalChunks: _bundle!.metadata.totalChunks,
        ),
      );
    }
    _encoder!.setPackets(packets);
    _transferStartedAt = DateTime.now();

    final historyId =
        '${_bundle!.session.id}-os-send-${DateTime.now().millisecondsSinceEpoch}';
    await ref.read(historyRepositoryProvider).addRecord(
          TransferRecord(
            id: historyId,
            sessionId: _bundle!.session.id,
            fileName: _bundle!.session.fileName,
            method: TransferMethod.opticalStream,
            sizeBytes: _bundle!.session.fileSize,
            status: TransferStatus.inProgress,
            timestamp: DateTime.now(),
            direction: TransferDirection.sent,
            compressionUsed:
                _bundle!.metadata.compression != CompressionType.none,
            encryptionUsed:
                _bundle!.metadata.encryption == EncryptionMode.enabled,
            profileUsed: state.transportProfile.id,
            protocolVersion: ProtocolVersions.metadataProtocolVersion,
            fecProfile: _fecRecovery.config.profile.id,
            parityOverhead: _fecRecovery.statistics.fecOverhead,
          ),
        );
    ref.invalidate(historyProvider);

    state = state.copyWith(
      phase: TransferPhase.transmitting,
      historyRecordId: historyId,
      totalFrames: packets.length,
    );

    void onFrame(OpticalStreamFrame frame, int index, int total) {
      _diagnostics.recordFrameGenerated();
      final raster = renderer.generateRaster(frame);
      final decision = adaptive.evaluateSenderFps(_diagnostics.current);
      final fps = decision.applied
          ? adaptive.state.mapped.framesPerSecond
          : state.framesPerSecond;
      if (decision.applied) {
        _encoder!.setFrameRate(fps);
      }
      state = state.copyWith(
        currentFrameIndex: index,
        totalFrames: total,
        loopCount: _encoder!.loopCount,
        currentOpticalRaster: raster,
        diagnostics: _diagnostics.current,
        framesPerSecond: fps,
        frameRate: fps,
        throughputBytesPerSec: _diagnostics.current.throughputBytesPerSecond,
        qualityScore: adaptive.state.qualityScore,
        syncLocked: true,
      );
    }

    _encoder!.start(
      framesPerSecond: state.framesPerSecond,
      onFrame: onFrame,
    );
  }

  void setFrameRate(double fps) {
    _encoder?.setFrameRate(fps);
    state = state.copyWith(framesPerSecond: fps, frameRate: fps);
  }

  Future<void> stopTransmission() async {
    _encoder?.stop();
    await _finalizeHistory(TransferStatus.cancelled);
    state = state.copyWith(phase: TransferPhase.cancelled);
  }

  void reset() {
    _encoder?.dispose();
    _encoder = null;
    _bundle = null;
    _sessionTransport = null;
    _keyExchangePayload = null;
    _keyProvider.clear();
    _diagnostics.reset();
    ref.read(opticalStreamSenderAdaptiveProvider).reset();
    state = OpticalStreamSenderState(
      framesPerSecond: ref.read(settingsProvider).opticalStreamSpeed,
      frameRate: ref.read(settingsProvider).opticalStreamSpeed,
    );
  }

  Future<void> _finalizeHistory(TransferStatus status) async {
    final id = state.historyRecordId;
    if (id == null) return;
    final adaptive = ref.read(opticalStreamSenderAdaptiveProvider);
    await adaptive.finalizeSession();
    final elapsed = _transferStartedAt != null
        ? DateTime.now().difference(_transferStartedAt!).inMilliseconds
        : 0;
    await ref.read(historyRepositoryProvider).replaceRecord(
          TransferRecord(
            id: id,
            sessionId: state.session?.id,
            fileName: state.session?.fileName ?? 'unknown',
            method: TransferMethod.opticalStream,
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
            protocolVersion: ProtocolVersions.metadataProtocolVersion,
            fecProfile: _fecRecovery.config.profile.id,
            packetsRecovered: _fecRecovery.statistics.packetsRecovered,
            recoveryRate: _fecRecovery.statistics.recoverySuccessRate,
            parityOverhead: _fecRecovery.statistics.fecOverhead,
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
