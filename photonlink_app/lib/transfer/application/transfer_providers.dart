import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/core/core_providers.dart';
import '../core/chunking_engine.dart';
import '../core/integrity_verifier.dart';
import '../core/payload_pipeline.dart';
import '../core/reconstruction_engine.dart';
import '../core/session_factory.dart';
import '../diagnostics/diagnostics_collector.dart';
import '../persistence/session_persistence_manager_impl.dart';
import '../qr/qr_frame_codec.dart';
import '../../services/storage/preferences_service.dart';
import 'color_matrix_receiver_controller.dart';
import 'color_matrix_sender_controller.dart';
import 'color_matrix_transfer_state.dart';
import 'optical_stream_receiver_controller.dart';
import 'optical_stream_sender_controller.dart';
import 'optical_stream_transfer_state.dart';
import 'receiver_controller.dart';
import 'sender_controller.dart';
import 'transfer_state.dart';

final chunkingEngineProvider = Provider<ChunkingEngine>(
  (ref) => const ChunkingEngine(),
);

final integrityVerifierProvider = Provider<IntegrityVerifier>(
  (ref) => const IntegrityVerifier(),
);

final reconstructionEngineProvider = Provider<ReconstructionEngine>(
  (ref) => ReconstructionEngine(
    chunkingEngine: ref.watch(chunkingEngineProvider),
  ),
);

final payloadPipelineProvider = Provider<PayloadPipeline>(
  (ref) => PayloadPipeline(
    compressionService: ref.watch(compressionServiceProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
    coreService: ref.watch(coreServiceProvider),
  ),
);

final sessionFactoryProvider = Provider<SessionFactory>(
  (ref) => SessionFactory(
    chunkManager: ref.watch(chunkingEngineProvider),
    coreService: ref.watch(coreServiceProvider),
  ),
);

final qrFrameCodecProvider = Provider<QrFrameCodec>(
  (ref) => const QrFrameCodec(),
);

final colorMatrixDiagnosticsCollectorProvider =
    Provider<FrameDiagnosticsCollector>(
  (ref) => FrameDiagnosticsCollector(ref.watch(preferencesServiceProvider)),
);

final opticalStreamDiagnosticsCollectorProvider =
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

/// Optical Stream continuous sender.
final opticalStreamSenderControllerProvider =
    NotifierProvider<OpticalStreamSenderController, OpticalStreamSenderState>(
  OpticalStreamSenderController.new,
);

/// Optical Stream camera receiver.
final opticalStreamReceiverControllerProvider =
    NotifierProvider<OpticalStreamReceiverController, OpticalStreamReceiverState>(
  OpticalStreamReceiverController.new,
);
