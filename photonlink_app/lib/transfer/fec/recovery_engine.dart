import '../../protocols/interfaces/transfer_packet.dart';
import '../core/reconstruction_engine.dart';
import 'fec_decoder.dart';
import 'fec_encoder.dart';
import 'models/fec_configuration.dart';
import 'models/fec_recovery_result.dart';
import 'models/fec_statistics.dart';

/// Orchestrates FEC recovery and integrates with [ReconstructionEngine].
class RecoveryEngine {
  RecoveryEngine({
    FecEncoder? encoder,
    FecDecoder? decoder,
  })  : _encoder = encoder ?? FecEncoder(),
        _decoder = decoder ?? FecDecoder();

  final FecEncoder _encoder;
  final FecDecoder _decoder;

  FecConfiguration _config = const FecConfiguration();
  FecStatistics _statistics = const FecStatistics();
  final Map<int, ParityPacket> _receivedParity = {};

  FecConfiguration get config => _config;
  FecStatistics get statistics => _statistics;

  void configure(FecConfiguration config) {
    _config = config;
  }

  void reset() {
    _config = const FecConfiguration();
    _statistics = const FecStatistics();
    _receivedParity.clear();
  }

  /// Generates parity packets for sending.
  List<ParityPacket> generateParity({
    required List<DataPacket> dataPackets,
    required String sessionId,
    required int totalChunks,
  }) {
    final parity = _encoder.encode(
      dataPackets: dataPackets,
      config: _config,
      sessionId: sessionId,
      totalChunks: totalChunks,
    );
    _statistics = _statistics.copyWith(parityGenerated: parity.length);
    return parity;
  }

  /// Ingests a parity packet from the transport layer.
  bool ingestParity(ParityPacket packet) {
    if (!_config.enabled) return false;
    if (_receivedParity.containsKey(packet.parityId)) return false;
    _receivedParity[packet.parityId] = packet;
    return true;
  }

  /// Identifies missing chunk IDs not yet in [recon].
  Set<int> missingChunkIds(ReconstructionEngine recon) {
    final meta = recon.metadata;
    if (meta == null) return {};
    final missing = <int>{};
    for (var i = 0; i < meta.totalChunks; i++) {
      if (!recon.receivedChunkIds.contains(i)) {
        missing.add(i);
      }
    }
    return missing;
  }

  /// Returns true if loss in any block is recoverable with available parity.
  bool hasRecoverableLoss(ReconstructionEngine recon) {
    if (!_config.enabled) return false;
    final missing = missingChunkIds(recon);
    if (missing.isEmpty) return false;

    // Simple heuristic: if we have any parity for blocks with missing data.
    return _receivedParity.isNotEmpty;
  }

  /// Attempts FEC recovery and injects recovered packets into [recon].
  FecRecoveryResult attemptRecovery(ReconstructionEngine recon) {
    if (!_config.enabled) return const FecRecoveryResult();

    final meta = recon.metadata;
    if (meta == null) return const FecRecoveryResult();

    final missing = missingChunkIds(recon);
    if (missing.isEmpty) return const FecRecoveryResult();

    final stopwatch = Stopwatch()..start();

    final result = _decoder.recover(
      config: _config,
      sessionId: meta.sessionId,
      totalChunks: meta.totalChunks,
      receivedData: _collectDataFromRecon(recon, meta.totalChunks),
      receivedParity: _receivedParity,
      missingChunkIds: missing,
    );

    stopwatch.stop();

    var recoveredCount = 0;
    for (final entry in result.recovered.entries) {
      if (recon.injectRecovered(entry.value)) {
        recoveredCount++;
      }
    }

    final successCount = result.blockSummaries.where((s) => s.success).length;
    _statistics = _statistics.copyWith(
      packetsLost: missing.length,
      packetsRecovered: _statistics.packetsRecovered + recoveredCount,
      recoveryAttempts: _statistics.recoveryAttempts + 1,
      recoverySuccessCount: _statistics.recoverySuccessCount +
          (successCount > 0 ? 1 : 0),
      parityConsumed: _statistics.parityConsumed + _receivedParity.length,
      recoveryTimeMs: _statistics.recoveryTimeMs + stopwatch.elapsedMilliseconds,
    );

    return FecRecoveryResult(
      recovered: result.recovered,
      unrecoverableBlocks: result.unrecoverableBlocks,
      blockSummaries: result.blockSummaries,
      success: recoveredCount > 0,
    );
  }

  /// Attempt recovery with explicit received data map (for testing / QR path).
  FecRecoveryResult attemptRecoveryWithData({
    required ReconstructionEngine recon,
    required Map<int, DataPacket> receivedData,
  }) {
    if (!_config.enabled) return const FecRecoveryResult();

    final meta = recon.metadata;
    if (meta == null) return const FecRecoveryResult();

    final missing = missingChunkIds(recon);
    if (missing.isEmpty) return const FecRecoveryResult();

    final stopwatch = Stopwatch()..start();

    final result = _decoder.recover(
      config: _config,
      sessionId: meta.sessionId,
      totalChunks: meta.totalChunks,
      receivedData: receivedData,
      receivedParity: _receivedParity,
      missingChunkIds: missing,
    );

    stopwatch.stop();

    var recoveredCount = 0;
    for (final entry in result.recovered.entries) {
      if (recon.injectRecovered(entry.value)) {
        recoveredCount++;
      }
    }

    _statistics = _statistics.copyWith(
      packetsLost: missing.length,
      packetsRecovered: _statistics.packetsRecovered + recoveredCount,
      recoveryAttempts: _statistics.recoveryAttempts + 1,
      recoverySuccessCount: _statistics.recoverySuccessCount +
          (recoveredCount > 0 ? 1 : 0),
      parityConsumed: _statistics.parityConsumed + _receivedParity.length,
      recoveryTimeMs: _statistics.recoveryTimeMs + stopwatch.elapsedMilliseconds,
    );

    return result;
  }

  Map<int, DataPacket> _collectDataFromRecon(
    ReconstructionEngine recon,
    int totalChunks,
  ) {
    return recon.exportReceivedData();
  }
}
