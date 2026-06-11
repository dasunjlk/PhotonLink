/// Application-wide constants.
abstract final class AppConstants {
  static const String appName = 'PhotonLink';
  static const String appTagline = 'Offline optical file transfer';
  static const String appVersion = '1.0.0';
  static const String phaseLabel = 'Phase 7 — Advanced Error Correction';

  /// PL2 metadata protocol version (1 = Phase 3, 2 = Phase 4, 3 = Phase 7 FEC).
  static const int protocolVersion = 3;

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
  static const String prefColorMatrixSize = 'color_matrix_size';
  static const String prefColorTransferFrameRate = 'color_transfer_frame_rate';
  static const String prefColorTransportQuality = 'color_transport_quality';
  static const String prefDebugOverlay = 'debug_overlay';
  static const String prefExperimentalFeatures = 'experimental_features';
  static const String prefAdaptiveMode = 'adaptive_mode_enabled';
  static const String prefAdaptiveAggressiveness = 'adaptive_aggressiveness';
  static const String prefProfileOverride = 'profile_override';
  static const String prefQualityMonitoring = 'quality_monitoring_enabled';
  static const String prefColorBitsPerChannel = 'color_bits_per_channel';
  static const String prefLastQualityScore = 'last_quality_score';
  static const String prefFecEnabled = 'fec_enabled';
  static const String prefFecProfile = 'fec_profile';
  static const String prefRedundancyPercent = 'redundancy_percent';
  static const String prefAdaptiveFecEnabled = 'adaptive_fec_enabled';
}
