import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/storage/preferences_service.dart';
import '../compression/compression_manager.dart';
import '../core/chunking_engine.dart';
import '../core/integrity_verifier.dart';
import '../core/payload_pipeline.dart';
import '../core/session_factory.dart';
import '../diagnostics/diagnostics_collector.dart';
import '../encryption/encryption_manager.dart';
import '../persistence/session_persistence_manager_impl.dart';
import '../qr/qr_frame_codec.dart';
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

final colorMatrixDiagnosticsCollectorProvider =
    Provider<FrameDiagnosticsCollector>(
  (ref) => FrameDiagnosticsCollector(ref.watch(preferencesServiceProvider)),
);

final sessionPersistenceManagerProvider =
    Provider<SessionPersistenceManagerImpl>((ref) {
  return SessionPersistenceManagerImpl(ref.watch(preferencesServiceProvider));
});

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
