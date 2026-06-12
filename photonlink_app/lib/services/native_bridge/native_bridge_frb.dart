import '../../src/rust/api.dart' as rust;
import 'native_bridge.dart';

/// Native bridge backed by the Rust core via flutter_rust_bridge.
class NativeBridgeFrb implements PhotonLinkNative {
  @override
  Future<String> coreVersion() async => rust.coreVersion();

  @override
  Future<String> ping() async {
    final version = await coreVersion();
    return 'pong (rust core $version)';
  }
}
