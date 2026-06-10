import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../protocols/interfaces/transfer_session.dart';
import '../../protocols/transport_registry.dart';
import '../color_matrix/color_matrix_frame.dart';
import '../color_matrix/color_matrix_frame_codec.dart';
import '../core/integrity_verifier.dart';
import '../core/payload_pipeline.dart';
import '../core/reconstruction_engine.dart';
import '../core/transfer_limits.dart';
import '../diagnostics/diagnostics_collector.dart';
import '../security/encryption_key_provider.dart';
import '../security/session_key_exchange.dart';
import 'color_matrix_transfer_state.dart';
import 'transfer_providers.dart';
import 'transfer_state.dart';

/// Color Matrix receiver: camera frames → decode → reconstruct → restore.
class ColorMatrixReceiverController extends Notifier<ColorMatrixReceiverState> {
  final _recon = ReconstructionEngine();
  final _keyProvider = EncryptionKeyProvider();
  final _keyExchange = SessionKeyExchange();
  late FrameDiagnosticsCollector _diagnostics;
  bool _finalizing = false;

  @override
  ColorMatrixReceiverState build() {
    _diagnostics = ref.read(colorMatrixDiagnosticsCollectorProvider);
    return const ColorMatrixReceiverState();
  }

  PayloadPipeline get _pipeline => ref.read(payloadPipelineProvider);
  IntegrityVerifier get _verifier => ref.read(integrityVerifierProvider);

  void startReceiving() {
    _recon.reset();
    _keyProvider.clear();
    _diagnostics.reset();
    _finalizing = false;
    state = const ColorMatrixReceiverState(
      phase: TransferPhase.waitingForReceiver,
    );
  }

  void onColorMatrixFrame(
    ColorMatrixFrame raw, {
    double detectionAccuracy = 0,
  }) {
    if (_finalizing || state.phase.isTerminal) return;
    if (state.phase == TransferPhase.reconstructing) return;

    _diagnostics.recordDetectionAccuracy(detectionAccuracy);
    final stopwatch = Stopwatch()..start();

    final transport = ref.read(colorMatrixTransportProvider);
    final packet = transport.decoder.decodeFrame(raw);
    stopwatch.stop();
    _diagnostics.recordDecodeTime(stopwatch.elapsed);

    if (packet == null) {
      _diagnostics.recordFrameCorrupted();
      _syncDiagnostics(detectionAccuracy: detectionAccuracy);
      return;
    }

    _handlePacket(packet, detectionAccuracy: detectionAccuracy);
  }

  void _handlePacket(
    TransferPacket packet, {
    required double detectionAccuracy,
  }) {
    switch (packet) {
      case MetadataPacket metadata:
        unawaited(
          _handleMetadata(metadata, detectionAccuracy: detectionAccuracy),
        );
      case DataPacket data:
        unawaited(_handleData(data, detectionAccuracy: detectionAccuracy));
      default:
        break;
    }
  }

  Future<void> _handleMetadata(
    MetadataPacket metadata, {
    required double detectionAccuracy,
  }) async {
    final transport = ref.read(colorMatrixTransportProvider);
    try {
      TransferLimits.validateMetadata(
        fileName: metadata.fileName,
        fileSize: metadata.fileSize,
        totalChunks: metadata.totalChunks,
        sha256: metadata.sha256,
        maxBytes: TransferLimits.maxColorMatrixFileBytes,
      );
    } catch (_) {
      _diagnostics.recordFrameCorrupted();
      _syncDiagnostics(detectionAccuracy: detectionAccuracy);
      return;
    }

    if (metadata.encryption == EncryptionMode.enabled && !_keyProvider.hasKey) {
      final keyPayload =
          (transport.decoder as ColorMatrixFrameCodec).lastDecodedKeyExchange;
      if (keyPayload == null) {
        _syncDiagnostics(detectionAccuracy: detectionAccuracy);
        return;
      }
      try {
        final key = await _keyExchange.acceptFromReceiver(keyPayload);
        _keyProvider.setSessionKey(key);
      } catch (_) {
        _diagnostics.recordFrameCorrupted();
        _syncDiagnostics(detectionAccuracy: detectionAccuracy);
        return;
      }
    }

    _recon.ingest(metadata);
    _diagnostics.recordFrameReceived();
    state = state.copyWith(
      phase: TransferPhase.receiving,
      session: TransferSession(
        id: metadata.sessionId,
        fileName: metadata.fileName,
        fileSize: metadata.originalSize ?? metadata.fileSize,
        totalChunks: metadata.totalChunks,
        sha256: metadata.originalSha256 ?? metadata.sha256,
        mimeType: metadata.mimeType,
        state: TransferSessionState.receiving,
        startedAt: DateTime.now(),
      ),
      totalChunks: metadata.totalChunks,
    );
    _syncDiagnostics(detectionAccuracy: detectionAccuracy);
  }

  Future<void> _handleData(
    DataPacket data, {
    required double detectionAccuracy,
  }) async {
    if (!_recon.hasMetadata) {
      _syncDiagnostics(detectionAccuracy: detectionAccuracy);
      return;
    }

    final accepted = _recon.ingest(data);
    if (!accepted) {
      _diagnostics.recordDuplicate();
      state = state.copyWith(
        duplicatesIgnored: state.duplicatesIgnored + 1,
      );
      _syncDiagnostics(detectionAccuracy: detectionAccuracy);
      return;
    }

    _diagnostics.recordFrameReceived(payloadBytes: data.payload.length);
    final missing = _recon.totalChunks - _recon.receivedCount;
    _diagnostics.updateMissingCount(missing);

    state = state.copyWith(
      receivedChunks: _recon.receivedCount,
      progress: _recon.progress,
      missingChunks: missing,
    );
    _syncDiagnostics(detectionAccuracy: detectionAccuracy);

    if (_recon.isComplete) {
      await _finalize();
    }
  }

  Future<void> _finalize() async {
    if (_finalizing) return;
    _finalizing = true;
    state = state.copyWith(phase: TransferPhase.reconstructing);

    try {
      final wireBytes = _recon.rebuild();
      final meta = _recon.metadata;
      if (wireBytes == null || meta == null) {
        throw StateError('Incomplete reconstruction');
      }
      if (wireBytes.length != meta.fileSize) {
        throw StateError('Reconstructed wire size mismatch');
      }
      if (!_verifier.verify(wireBytes, meta.sha256)) {
        throw StateError('Wire payload SHA-256 check failed');
      }

      final plaintext = await _pipeline.restorePlaintext(
        wireBytes: wireBytes,
        meta: MetadataPacketFields(
          compression: meta.compression,
          encryption: meta.encryption,
          originalSize: meta.originalSize,
          originalSha256: meta.originalSha256,
        ),
        keyProvider: _keyProvider,
      );

      final expectedSize = meta.originalSize ?? meta.fileSize;
      final expectedHash = meta.originalSha256 ?? meta.sha256;
      if (plaintext.length != expectedSize) {
        throw StateError('Plaintext size mismatch after decompress');
      }
      if (!_verifier.verify(plaintext, expectedHash)) {
        throw StateError('Original file SHA-256 check failed');
      }

      final dir = await getApplicationDocumentsDirectory();
      final safeName = meta.fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
      final outputPath = '${dir.path}/$safeName';
      await File(outputPath).writeAsBytes(plaintext, flush: true);

      _keyProvider.clear();

      state = state.copyWith(
        phase: TransferPhase.completed,
        outputPath: outputPath,
        integrityValid: true,
        progress: 1.0,
        receivedChunks: meta.totalChunks,
        missingChunks: 0,
      );
    } catch (e) {
      _keyProvider.clear();
      state = state.copyWith(
        phase: TransferPhase.failed,
        errorMessage: e.toString(),
        integrityValid: false,
      );
    }
  }

  void _syncDiagnostics({required double detectionAccuracy}) {
    state = state.copyWith(
      diagnostics: _diagnostics.current,
      detectionAccuracy: detectionAccuracy,
      missingChunks: _recon.hasMetadata
          ? _recon.totalChunks - _recon.receivedCount
          : state.missingChunks,
    );
  }

  void reset() {
    _recon.reset();
    _keyProvider.clear();
    _diagnostics.reset();
    _finalizing = false;
    state = const ColorMatrixReceiverState();
  }
}
