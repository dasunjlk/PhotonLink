import '../../../protocols/interfaces/transfer_packet.dart';
import '../../../transfer/core/reconstruction_engine.dart';
import '../../../transfer/fec/models/fec_configuration.dart';
import '../../../transfer/fec/models/fec_recovery_result.dart';
import '../../../transfer/fec/models/fec_statistics.dart';
import '../../../transfer/fec/recovery_engine.dart';
import '../fec_service.dart';

/// Dart backend — delegates to [RecoveryEngine].
class DartFecService implements FecService {
  DartFecService({RecoveryEngine? engine})
      : _engine = engine ?? RecoveryEngine();

  final RecoveryEngine _engine;

  @override
  FecConfiguration get config => _engine.config;

  @override
  FecStatistics get statistics => _engine.statistics;

  @override
  void configure(FecConfiguration config) => _engine.configure(config);

  @override
  void reset() => _engine.reset();

  @override
  List<ParityPacket> generateParity({
    required List<DataPacket> dataPackets,
    required String sessionId,
    required int totalChunks,
  }) =>
      _engine.generateParity(
        dataPackets: dataPackets,
        sessionId: sessionId,
        totalChunks: totalChunks,
      );

  @override
  bool ingestParity(ParityPacket packet) => _engine.ingestParity(packet);

  @override
  Set<int> missingChunkIds(ReconstructionEngine recon) =>
      _engine.missingChunkIds(recon);

  @override
  FecRecoveryResult attemptRecovery(ReconstructionEngine recon) =>
      _engine.attemptRecovery(recon);
}

/// Rust-backed FEC service — wraps RecoveryEngine for now; RS codec
/// can be swapped to Rust via PhotonLinkCoreApi when backend is rust.
class RustFecService extends DartFecService {
  RustFecService({RecoveryEngine? engine}) : super(engine: engine);
}
