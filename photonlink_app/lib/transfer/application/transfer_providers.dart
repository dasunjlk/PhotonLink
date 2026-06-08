import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../protocols/transport_registry.dart';
import '../../services/storage/preferences_service.dart';
import '../compression/compression_manager.dart';
import '../core/chunking_engine.dart';
import '../core/integrity_verifier.dart';
import '../core/payload_pipeline.dart';
import '../core/session_factory.dart';
import '../diagnostics/diagnostics_collector.dart';
import '../encryption/encryption_manager.dart';
import '../metrics/throughput_monitor.dart';
import '../persistence/received_chunk_store.dart';
import '../persistence/session_persistence_manager_impl.dart';
import '../qr/qr_frame_codec.dart';
import '../reliability/acknowledgement_manager_impl.dart';
import '../reliability/diagnostics_collector_impl.dart';
import '../reliability/missing_packet_tracker_impl.dart';
import '../reliability/retry_manager_impl.dart';
import '../reliability/transfer_recovery_manager_impl.dart';
import '../scheduler/transfer_scheduler.dart';
import '../security/encryption_key_provider.dart';
import '../security/session_key_exchange.dart';
import 'color_matrix_receiver_controller.dart';
import 'color_matrix_sender_controller.dart';
import 'color_matrix_transfer_state.dart';
import 'receiver_controller.dart';
import 'sender_controller.dart';
import 'transfer_state.dart';

final chunkingEngineProvider = Provider<ChunkingEngine>(
  (ref) => const ChunkingEngine(),
);

final integrityVerifierProvider = Provider<IntegrityVerifier>(
  (ref) => const IntegrityVerifier(),
);

final compressionManagerProvider = Provider<CompressionManager>(
  (ref) => CompressionManager(),
);

final encryptionManagerProvider = Provider<EncryptionManager>(
  (ref) => EncryptionManager(),
);

final payloadPipelineProvider = Provider<PayloadPipeline>(
  (ref) => PayloadPipeline(
    compressionManager: ref.watch(compressionManagerProvider),
    encryptionManager: ref.watch(encryptionManagerProvider),
    integrityVerifier: ref.watch(integrityVerifierProvider),
  ),
);

final sessionFactoryProvider = Provider<SessionFactory>(
  (ref) => SessionFactory(
    chunkManager: ref.watch(chunkingEngineProvider),
    integrityVerifier: ref.watch(integrityVerifierProvider),
  ),
);

final qrFrameCodecProvider = Provider<QrFrameCodec>(
  (ref) => const QrFrameCodec(),
);

final missingPacketTrackerProvider = Provider<MissingPacketTrackerImpl>(
  (ref) => MissingPacketTrackerImpl(),
);

final acknowledgementManagerProvider = Provider<AcknowledgementManagerImpl>(
  (ref) => AcknowledgementManagerImpl(),
);

final retryManagerProvider = Provider<RetryManagerImpl>(
  (ref) => RetryManagerImpl(),
);

final diagnosticsCollectorProvider = Provider<DiagnosticsCollectorImpl>(
  (ref) => DiagnosticsCollectorImpl(),
);

final colorMatrixDiagnosticsCollectorProvider = Provider<DiagnosticsCollector>(
  (ref) => DiagnosticsCollector(ref.watch(preferencesServiceProvider)),
);

final transferRecoveryManagerProvider = Provider<TransferRecoveryManagerImpl>(
  (ref) => TransferRecoveryManagerImpl(),
);

final receivedChunkStoreProvider = Provider<ReceivedChunkStore>(
  (ref) => ReceivedChunkStore(),
);

final sessionPersistenceManagerProvider =
    Provider<SessionPersistenceManagerImpl>((ref) {
  return SessionPersistenceManagerImpl(ref.watch(preferencesServiceProvider));
});

final transferSchedulerProvider = Provider<TransferScheduler>(
  (ref) => const TransferScheduler(),
);

final throughputMonitorProvider = Provider<ThroughputMonitor>(
  (ref) => ThroughputMonitor(),
);

final encryptionKeyProviderProvider = Provider<EncryptionKeyProvider>(
  (ref) => EncryptionKeyProvider(),
);

final sessionKeyExchangeProvider = Provider<SessionKeyExchange>(
  (ref) => SessionKeyExchange(),
);

/// QR bidirectional sender (Phase 4).
final senderControllerProvider =
    NotifierProvider<SenderController, SenderTransferState>(
  SenderController.new,
);

/// QR bidirectional receiver (Phase 4).
final receiverControllerProvider =
    NotifierProvider<ReceiverController, ReceiverTransferState>(
  ReceiverController.new,
);

/// Color Matrix cyclic sender.
final colorMatrixSenderControllerProvider =
    NotifierProvider<ColorMatrixSenderController, ColorMatrixSenderState>(
  ColorMatrixSenderController.new,
);

/// Color Matrix camera receiver.
final colorMatrixReceiverControllerProvider =
    NotifierProvider<ColorMatrixReceiverController, ColorMatrixReceiverState>(
  ColorMatrixReceiverController.new,
);
