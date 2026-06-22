/// Canonical protocol and schema version constants.
abstract final class ProtocolVersions {
  /// PL2 metadata version (QR setup/metadata packets).
  static const int metadataProtocolVersion = 3;

  /// PLCM wire format version (Color Matrix frames).
  static const int plcmWireVersion = 1;

  /// PLOS wire format version (Optical Stream frames).
  static const int plosWireVersion = 1;

  /// SharedPreferences history JSON schema.
  static const int historySchemaVersion = 5;

  /// Key exchange wire format (1 = X25519 ECDH).
  static const int keyExchangeVersion = 1;
}
