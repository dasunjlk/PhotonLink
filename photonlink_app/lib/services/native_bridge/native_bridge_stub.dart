import 'native_bridge.dart';

/// Stub implementation returning mock data until Rust FFI is wired in Phase 2.
class NativeBridgeStub implements PhotonLinkNative {
  @override
  Future<String> coreVersion() async => '0.1.0-stub';

  @override
  Future<String> ping() async => 'pong (dart stub — Rust core not connected)';
}
