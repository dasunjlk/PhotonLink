import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../protocols/transfer_method.dart';
import '../../services/storage/preferences_service.dart';
import '../core/chunking_engine.dart';
import '../core/integrity_verifier.dart';
import '../core/payload_pipeline.dart';
import '../core/session_factory.dart';
import '../core/session_store.dart';
import '../diagnostics/diagnostics_collector.dart';
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

final payloadPipelineProvider = Provider<PayloadPipeline>(
  (ref) => PayloadPipeline(),
);

final sessionFactoryProvider = Provider<SessionFactory>(
  (ref) => SessionFactory(
    chunkManager: ref.watch(chunkingEngineProvider),
    integrityVerifier: ref.watch(integrityVerifierProvider),
    payloadPipeline: ref.watch(payloadPipelineProvider),
  ),
);

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SessionStore(ref.watch(preferencesServiceProvider));
});

final transferRecoveryManagerProvider =
    Provider<TransferRecoveryManagerImpl>((ref) {
  return TransferRecoveryManagerImpl(ref.watch(sessionStoreProvider));
});

final diagnosticsCollectorProvider = Provider<DiagnosticsCollector>((ref) {
  return DiagnosticsCollector(ref.watch(preferencesServiceProvider));
});

final senderControllerProvider = NotifierProvider.family<
    SenderController, SenderTransferState, TransferMethod>(
  SenderController.new,
);

final receiverControllerProvider = NotifierProvider.family<
    ReceiverController, ReceiverTransferState, TransferMethod>(
  ReceiverController.new,
);

/// Legacy QR-only providers for backward compatibility.
final qrSenderControllerProvider = senderControllerProvider(TransferMethod.qr);
final qrReceiverControllerProvider =
    receiverControllerProvider(TransferMethod.qr);
