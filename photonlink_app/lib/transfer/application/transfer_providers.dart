import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/storage/preferences_service.dart';
import '../core/chunking_engine.dart';
import '../core/integrity_verifier.dart';
import '../core/session_factory.dart';
import '../persistence/received_chunk_store.dart';
import '../persistence/session_persistence_manager_impl.dart';
import '../qr/qr_frame_codec.dart';
import '../reliability/acknowledgement_manager_impl.dart';
import '../reliability/diagnostics_collector_impl.dart';
import '../reliability/missing_packet_tracker_impl.dart';
import '../reliability/retry_manager_impl.dart';
import '../reliability/transfer_recovery_manager_impl.dart';
import 'receiver_controller.dart';
import 'sender_controller.dart';
import 'transfer_state.dart';

final chunkingEngineProvider = Provider<ChunkingEngine>(
  (ref) => const ChunkingEngine(),
);

final integrityVerifierProvider = Provider<IntegrityVerifier>(
  (ref) => const IntegrityVerifier(),
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

final senderControllerProvider =
    NotifierProvider<SenderController, SenderTransferState>(
  SenderController.new,
);

final receiverControllerProvider =
    NotifierProvider<ReceiverController, ReceiverTransferState>(
  ReceiverController.new,
);
