import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transfer/compression/compression_manager.dart';
import '../../transfer/encryption/encryption_manager.dart';
import '../../transfer/fec/recovery_engine.dart';
import 'compression_service.dart';
import 'core_backend.dart';
import 'core_service.dart';
import 'diagnostics_service.dart';
import 'encryption_service.dart';
import 'fec_service.dart';
import 'impl/dart_compression_service.dart';
import 'impl/dart_core_service.dart';
import 'impl/dart_diagnostics_service.dart';
import 'impl/dart_encryption_service.dart';
import 'impl/dart_fec_service.dart';
import 'impl/dart_packet_service.dart';
import 'packet_service.dart';
import 'photon_link_core_api.dart';

/// Active backend selection (default: dart).
final backendProvider = Provider<CoreBackend>(
  (ref) => CoreBackend.dart,
);

/// Rust core API — returns [NotConnectedCoreApi] until FRB codegen is run.
final photonLinkCoreApiProvider = Provider<PhotonLinkCoreApi>(
  (ref) => const NotConnectedCoreApi(),
);

final coreServiceProvider = Provider<CoreService>((ref) {
  if (ref.watch(backendProvider) == CoreBackend.rust) {
    return RustCoreService(ref.watch(photonLinkCoreApiProvider));
  }
  return const DartCoreService();
});

final compressionServiceProvider = Provider<CompressionService>((ref) {
  if (ref.watch(backendProvider) == CoreBackend.rust) {
    return RustCompressionService(ref.watch(photonLinkCoreApiProvider));
  }
  return DartCompressionService(
    manager: ref.watch(compressionManagerProvider),
  );
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  if (ref.watch(backendProvider) == CoreBackend.rust) {
    return RustEncryptionService(ref.watch(photonLinkCoreApiProvider));
  }
  return DartEncryptionService(
    manager: ref.watch(encryptionManagerProvider),
  );
});

final packetServiceProvider = Provider<PacketService>((ref) {
  if (ref.watch(backendProvider) == CoreBackend.rust) {
    return RustPacketService(ref.watch(photonLinkCoreApiProvider));
  }
  return const DartPacketService();
});

final diagnosticsServiceProvider = Provider<DiagnosticsService>((ref) {
  if (ref.watch(backendProvider) == CoreBackend.rust) {
    return RustDiagnosticsService(ref.watch(photonLinkCoreApiProvider));
  }
  return const DartDiagnosticsService();
});

final fecServiceProvider = Provider<FecService>((ref) {
  final engine = RecoveryEngine();
  if (ref.watch(backendProvider) == CoreBackend.rust) {
    return RustFecService(engine: engine);
  }
  return DartFecService(engine: engine);
});

/// Legacy manager providers — used by service layer and direct call sites.
final compressionManagerProvider = Provider<CompressionManager>(
  (ref) => CompressionManager(),
);

final encryptionManagerProvider = Provider<EncryptionManager>(
  (ref) => EncryptionManager(),
);

final recoveryEngineProvider = Provider<RecoveryEngine>(
  (ref) => RecoveryEngine(),
);
