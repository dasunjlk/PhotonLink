import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/reliability/acknowledgement_manager.dart';
import '../../protocols/interfaces/reliability/diagnostics_collector.dart';
import '../../protocols/interfaces/reliability/missing_packet_tracker.dart';
import '../../protocols/interfaces/reliability/retry_manager.dart';
import '../../protocols/interfaces/reliability/transfer_recovery_manager.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../compression/compression_manager.dart';
import '../core/payload_pipeline.dart';
import '../core/reconstruction_engine.dart';
import '../encryption/encryption_manager.dart';
import '../metrics/throughput_monitor.dart';
import '../persistence/received_chunk_store.dart';
import '../reliability/acknowledgement_manager_impl.dart';
import '../reliability/diagnostics_collector_impl.dart';
import '../reliability/missing_packet_tracker_impl.dart';
import '../reliability/retry_manager_impl.dart';
import '../reliability/transfer_recovery_manager_impl.dart';
import '../scheduler/transfer_scheduler.dart';
import '../security/encryption_key_provider.dart';
import '../security/key_exchange.dart';
import '../security/session_key_exchange.dart';
import '../../settings/domain/app_settings.dart';
import '../fec/fec_configuration_factory.dart';
import '../fec/models/fec_configuration.dart';
import '../fec/recovery_engine.dart';
import '../state/transfer_phase.dart';
import '../state/transfer_state_machine.dart';

/// Bundles reliability + Phase 4 efficiency managers (transport-agnostic).
class ReliableTransferContext {
  ReliableTransferContext({
    required this.role,
    TransferStateMachine? stateMachine,
    MissingPacketTracker? tracker,
    AcknowledgementManager? ackManager,
    RetryManager? retryManager,
    DiagnosticsCollector? diagnostics,
    TransferRecoveryManager? recovery,
    ReceivedChunkStore? chunkStore,
    ReconstructionEngine? reconstruction,
    CompressionManager? compressionManager,
    EncryptionManager? encryptionManager,
    PayloadPipeline? payloadPipeline,
    KeyExchange? keyExchange,
    EncryptionKeyProvider? keyProvider,
    TransferScheduler? scheduler,
    ThroughputMonitor? throughputMonitor,
    RecoveryEngine? fecRecovery,
  })  : stateMachine = stateMachine ?? TransferStateMachine(role: role),
        tracker = tracker ?? MissingPacketTrackerImpl(),
        ackManager = ackManager ?? AcknowledgementManagerImpl(),
        retryManager = retryManager ?? RetryManagerImpl(),
        diagnostics = diagnostics ?? DiagnosticsCollectorImpl(),
        recovery = recovery ?? TransferRecoveryManagerImpl(),
        chunkStore = chunkStore ?? ReceivedChunkStore(),
        reconstruction = reconstruction ?? ReconstructionEngine(),
        compressionManager = compressionManager ?? CompressionManager(),
        encryptionManager = encryptionManager ?? EncryptionManager(),
        payloadPipeline = payloadPipeline ?? PayloadPipeline(),
        keyExchange = keyExchange ?? SessionKeyExchange(),
        keyProvider = keyProvider ?? EncryptionKeyProvider(),
        scheduler = scheduler ?? const TransferScheduler(),
        throughput = throughputMonitor ?? ThroughputMonitor(),
        fecRecovery = fecRecovery ?? RecoveryEngine();

  final TransferRole role;
  final TransferStateMachine stateMachine;
  final MissingPacketTracker tracker;
  final AcknowledgementManager ackManager;
  final RetryManager retryManager;
  final DiagnosticsCollector diagnostics;
  final TransferRecoveryManager recovery;
  final ReceivedChunkStore chunkStore;
  final ReconstructionEngine reconstruction;
  final CompressionManager compressionManager;
  final EncryptionManager encryptionManager;
  final PayloadPipeline payloadPipeline;
  final KeyExchange keyExchange;
  final EncryptionKeyProvider keyProvider;
  final TransferScheduler scheduler;
  final ThroughputMonitor throughput;
  final RecoveryEngine fecRecovery;

  MetadataPacket? metadata;
  SessionSetupPacket? setupPacket;
  int roundNumber = 0;
  bool isFinalizing = false;
  bool paritySent = false;

  static final _fecFactory = FecConfigurationFactory();

  void reset() {
    metadata = null;
    setupPacket = null;
    roundNumber = 0;
    isFinalizing = false;
    paritySent = false;
    stateMachine.forcePhase(TransferPhase.idle);
    diagnostics.reset();
    throughput.reset();
    keyProvider.clear();
    fecRecovery.reset();
  }

  void configureFec(FecConfiguration config) {
    fecRecovery.configure(config);
  }

  FecConfiguration fecFromSettings(AppSettings settings) {
    return _fecFactory.fromSettings(settings);
  }

  void bindSession(MetadataPacket meta) {
    metadata = meta;
    tracker.reset(sessionId: meta.sessionId, totalPackets: meta.totalChunks);
    ackManager.reset(sessionId: meta.sessionId, totalPackets: meta.totalChunks);
    retryManager.reset(totalPackets: meta.totalChunks);
    diagnostics.startSession();
    diagnostics.setEncryptionUsed(meta.encryption == EncryptionMode.enabled);
    reconstruction.reset();
    throughput.start();
  }

  List<DataPacket> packetsForIds(
    List<DataPacket> all,
    Set<int> ids,
  ) {
    return all.where((p) => ids.contains(p.chunkId)).toList();
  }

  NakPacket buildNak() {
    final meta = metadata!;
    diagnostics.recordNak();
    return NakPacket(
      sessionId: meta.sessionId,
      missingPacketIds: tracker.missingIds.toList()..sort(),
      timestamp: DateTime.now(),
    );
  }

  AckPacket buildFullAck() {
    final meta = metadata!;
    diagnostics.recordAck();
    return ackManager.buildAck(
      sessionId: meta.sessionId,
      packetIds: List.generate(meta.totalChunks, (i) => i),
    );
  }

  HandshakePacket buildHandshake() {
    final meta = metadata!;
    return HandshakePacket(
      sessionId: meta.sessionId,
      receivedChunkIds: tracker.receivedIds.toList()..sort(),
      timestamp: DateTime.now(),
    );
  }
}
