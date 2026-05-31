import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract interface for the Rust native core bridge.
/// Phase 2 will replace the stub with flutter_rust_bridge bindings.
abstract interface class PhotonLinkNative {
  /// Returns the version string from the Rust core.
  Future<String> coreVersion();

  /// Health-check ping to verify bridge connectivity.
  Future<String> ping();
}

/// Provider for the native bridge implementation.
final nativeBridgeProvider = Provider<PhotonLinkNative>(
  (ref) => throw UnimplementedError('NativeBridge not initialized'),
);
