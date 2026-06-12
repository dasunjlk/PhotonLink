import 'dart:typed_data';

import '../../../protocols/interfaces/encryption_mode.dart';
import '../../../transfer/encryption/encryption_manager.dart';
import '../encryption_service.dart';
import '../photon_link_core_api.dart';

/// Dart backend — delegates to [EncryptionManager].
class DartEncryptionService implements EncryptionService {
  DartEncryptionService({EncryptionManager? manager})
      : _manager = manager ?? EncryptionManager();

  final EncryptionManager _manager;

  @override
  Future<Uint8List> encryptIfEnabled({
    required Uint8List plaintext,
    required Uint8List sessionKey,
    required EncryptionMode mode,
  }) =>
      _manager.encryptIfEnabled(
        plaintext: plaintext,
        sessionKey: sessionKey,
        mode: mode,
      );

  @override
  Future<Uint8List> decryptIfEnabled({
    required Uint8List wireBytes,
    required Uint8List sessionKey,
    required EncryptionMode mode,
  }) =>
      _manager.decryptIfEnabled(
        wireBytes: wireBytes,
        sessionKey: sessionKey,
        mode: mode,
      );
}

/// Rust backend for encryption.
class RustEncryptionService implements EncryptionService {
  const RustEncryptionService(this._api);

  final PhotonLinkCoreApi _api;

  @override
  Future<Uint8List> encryptIfEnabled({
    required Uint8List plaintext,
    required Uint8List sessionKey,
    required EncryptionMode mode,
  }) async {
    if (mode == EncryptionMode.disabled) return plaintext;
    return _api.encryptData(plaintext, sessionKey);
  }

  @override
  Future<Uint8List> decryptIfEnabled({
    required Uint8List wireBytes,
    required Uint8List sessionKey,
    required EncryptionMode mode,
  }) async {
    if (mode == EncryptionMode.disabled) return wireBytes;
    return _api.decryptData(wireBytes, sessionKey);
  }
}
