import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/storage/preferences_service.dart';
import '../core/chunking_engine.dart';
import '../core/integrity_verifier.dart';
import '../core/session_factory.dart';
import '../core/session_store.dart';
import '../qr/qr_frame_codec.dart';
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

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SessionStore(ref.watch(preferencesServiceProvider));
});

final senderControllerProvider =
    NotifierProvider<SenderController, SenderTransferState>(
  SenderController.new,
);

final receiverControllerProvider =
    NotifierProvider<ReceiverController, ReceiverTransferState>(
  ReceiverController.new,
);
