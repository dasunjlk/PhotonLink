import 'dart:typed_data';

/// Holds session encryption key for the duration of a transfer.
class EncryptionKeyProvider {
  Uint8List? _sessionKey;

  bool get hasKey => _sessionKey != null;

  Uint8List get sessionKey {
    final k = _sessionKey;
    if (k == null) {
      throw StateError('Session key not established');
    }
    return k;
  }

  void setSessionKey(Uint8List key) {
    _sessionKey = Uint8List.fromList(key);
  }

  void clear() {
    if (_sessionKey != null) {
      for (var i = 0; i < _sessionKey!.length; i++) {
        _sessionKey![i] = 0;
      }
    }
    _sessionKey = null;
  }
}
