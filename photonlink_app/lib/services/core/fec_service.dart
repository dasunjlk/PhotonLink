import '../../protocols/interfaces/transfer_packet.dart';
import '../../transfer/core/reconstruction_engine.dart';
import '../../transfer/fec/models/fec_configuration.dart';
import '../../transfer/fec/models/fec_recovery_result.dart';
import '../../transfer/fec/models/fec_statistics.dart';

/// FEC recovery operations (Phase 8C).
abstract interface class FecService {
  FecConfiguration get config;
  FecStatistics get statistics;

  void configure(FecConfiguration config);
  void reset();

  List<ParityPacket> generateParity({
    required List<DataPacket> dataPackets,
    required String sessionId,
    required int totalChunks,
  });

  bool ingestParity(ParityPacket packet);
  Set<int> missingChunkIds(ReconstructionEngine recon);
  FecRecoveryResult attemptRecovery(ReconstructionEngine recon);
}
