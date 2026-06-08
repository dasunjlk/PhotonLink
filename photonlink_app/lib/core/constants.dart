/// Application-wide constants.
abstract final class AppConstants {
  static const String appName = 'PhotonLink';
  static const String appTagline = 'Offline optical file transfer';
  static const String appVersion = '1.0.0';
  static const String phaseLabel = 'Phase 4 — Efficiency & Security';

  /// PL2 metadata protocol version (1 = Phase 3, 2 = Phase 4).
  static const int protocolVersion = 2;

  // SharedPreferences keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefCompression = 'compression_enabled';
  static const String prefCompressionMode = 'compression_mode';
  static const String prefEncryption = 'encryption_enabled';
  static const String prefTransferMode = 'transfer_mode';
  static const String prefDiagnosticsEnabled = 'diagnostics_enabled';
  static const String prefPreferredMethod = 'preferred_method';
  static const String prefCameraResolution = 'camera_resolution';
}
