import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../protocols/transport_registry.dart';
import '../../settings/application/settings_controller.dart';
import '../color_matrix/color_frame_generator.dart';
import '../color_matrix/color_matrix_frame.dart';
import '../color_matrix/color_matrix_frame_codec.dart';
import '../color_matrix/color_matrix_transfer_limits.dart';
import '../core/frame_stream_controller.dart';
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
  final _keyProvider = EncryptionKeyProvider();
  final _keyExchange = SessionKeyExchange();
  late DiagnosticsCollector _diagnostics;

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
    required String filePath,
    required String fileName,
    required String? extension,
  }) async {
    _stream?.dispose();
    _stream = null;
    _bundle = null;
    _keyExchangePayload = null;
    _keyProvider.clear();
    _diagnostics.reset();

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

      final file = File(filePath);
      TransferLimits.validateFileSize(await file.length());
      final bytes = Uint8List.fromList(await file.readAsBytes());

      final settings = ref.read(settingsProvider);
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

      final transport = ref.read(colorMatrixTransportProvider);
      final codec = transport.encoder as ColorMatrixFrameCodec;
      final sessionId = _sessionFactory.generateSessionId();
      final chunkSize = ColorMatrixTransferLimits.resolveChunkSize(
        sessionId: sessionId,
        fileBytes: prepared.wireBytes,
        chunkManager: ref.read(chunkingEngineProvider),
        encoder: codec,
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
        framesPerSecond: settings.colorTransferFrameRate,
        compression: compression,
        encryption: encryption,
        diagnostics: _diagnostics.current,
      );
    } on TransferLimitException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<void> startTransmission() async {
    if (_bundle == null) return;

    final transport = ref.read(colorMatrixTransportProvider);
    final codec = transport.encoder as ColorMatrixFrameCodec;
    codec.encoderKeyExchangePayload = _keyExchangePayload;
    final generator = ColorFrameGenerator(
      showDebugOverlay: ref.read(settingsProvider).debugOverlay,
    );

    _stream = FrameStreamController<ColorMatrixFrame>(
      encoder: transport.encoder,
    );

    final packets = <TransferPacket>[
      _bundle!.metadata,
      ..._bundle!.dataPackets,
    ];
    _stream!.setPackets(packets);

    state = state.copyWith(phase: TransferPhase.transmitting);

    _stream!.start(
      framesPerSecond: state.framesPerSecond,
      onFrame: (frame, index, total) {
        _diagnostics.recordFrameGenerated();
        final raster = generator.generateRaster(frame);
        state = state.copyWith(
          currentFrameIndex: index,
          totalFrames: total,
          loopCount: _stream!.loopCount,
          currentColorMatrixRaster: raster,
          diagnostics: _diagnostics.current,
        );
      },
    );
  }

  void setFrameRate(double fps) {
    _stream?.setFrameRate(fps);
    state = state.copyWith(framesPerSecond: fps);
  }

  void stopTransmission() {
    _stream?.stop();
    state = state.copyWith(phase: TransferPhase.cancelled);
  }

  void reset() {
    _stream?.dispose();
    _stream = null;
    _bundle = null;
    _keyExchangePayload = null;
    _keyProvider.clear();
    _diagnostics.reset();
    state = ColorMatrixSenderState(
      framesPerSecond: ref.read(settingsProvider).colorTransferFrameRate,
    );
  }

  void _fail(String message) {
    state = state.copyWith(
      phase: TransferPhase.failed,
      errorMessage: message,
    );
  }
}
