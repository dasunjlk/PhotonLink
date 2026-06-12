import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/transfer_method.dart';
import '../../services/storage/preferences_service.dart';
import '../../transfer/adaptive/models/transport_profile.dart';
import '../../transfer/fec/models/fec_profile.dart';
import '../../transfer/scheduler/transfer_mode.dart';
import '../domain/app_settings.dart';

/// Persists and loads [AppSettings] from SharedPreferences.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final PreferencesService _prefs;

  AppSettings load() {
    final themeIndex = _prefs.getInt(AppConstants.prefThemeMode);
    final language = _prefs.getString(AppConstants.prefLanguage);
    final compression = _prefs.getBool(AppConstants.prefCompression);
    final compressionModeId =
        _prefs.getString(AppConstants.prefCompressionMode);
    final encryption = _prefs.getBool(AppConstants.prefEncryption);
    final transferModeId = _prefs.getString(AppConstants.prefTransferMode);
    final diagnostics =
        _prefs.getBool(AppConstants.prefDiagnosticsEnabled);
    final methodId = _prefs.getString(AppConstants.prefPreferredMethod);
    final cameraResolution = _prefs.getString(AppConstants.prefCameraResolution);
    final colorMatrixSize = _prefs.getInt(AppConstants.prefColorMatrixSize);
    final colorFrameRate =
        _prefs.getDouble(AppConstants.prefColorTransferFrameRate);
    final colorQuality =
        _prefs.getString(AppConstants.prefColorTransportQuality);
    final colorBpc = _prefs.getInt(AppConstants.prefColorBitsPerChannel);
    final adaptiveMode = _prefs.getBool(AppConstants.prefAdaptiveMode);
    final aggressivenessId =
        _prefs.getString(AppConstants.prefAdaptiveAggressiveness);
    final profileOverrideId = _prefs.getString(AppConstants.prefProfileOverride);
    final qualityMonitoring =
        _prefs.getBool(AppConstants.prefQualityMonitoring);
    final debugOverlay = _prefs.getBool(AppConstants.prefDebugOverlay);
    final experimental =
        _prefs.getBool(AppConstants.prefExperimentalFeatures);
    final fecEnabled = _prefs.getBool(AppConstants.prefFecEnabled);
    final fecProfileId = _prefs.getString(AppConstants.prefFecProfile);
    final redundancyPercent =
        _prefs.getInt(AppConstants.prefRedundancyPercent);
    final adaptiveFecEnabled =
        _prefs.getBool(AppConstants.prefAdaptiveFecEnabled);
    final opticalStreamSpeed =
        _prefs.getDouble(AppConstants.prefOpticalStreamSpeed);
    final opticalStreamDensity =
        _prefs.getInt(AppConstants.prefOpticalStreamDensity);
    final opticalSyncAggressiveness =
        _prefs.getDouble(AppConstants.prefOpticalSyncAggressiveness);
    final opticalRecoverySensitivity =
        _prefs.getDouble(AppConstants.prefOpticalRecoverySensitivity);
    final opticalStreamDiagnostics =
        _prefs.getBool(AppConstants.prefOpticalStreamDiagnostics);

    return AppSettings(
      themeMode: themeIndex != null
          ? ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)]
          : ThemeMode.dark,
      language: language ?? 'en',
      compressionEnabled: compression ?? false,
      compressionMode: CompressionType.fromId(compressionModeId),
      encryptionEnabled: encryption ?? false,
      transferMode: TransferMode.fromId(transferModeId),
      diagnosticsEnabled: diagnostics ?? true,
      preferredMethod: _methodFromId(methodId),
      cameraResolution: cameraResolution ?? 'high',
      colorMatrixSize: _validGridSize(colorMatrixSize),
      colorTransferFrameRate: colorFrameRate ?? 4.0,
      colorTransportQuality: colorQuality ?? 'balanced',
      colorBitsPerChannel: _validBitsPerChannel(colorBpc),
      adaptiveModeEnabled: adaptiveMode ?? true,
      adaptiveAggressiveness:
          AdaptiveAggressiveness.fromId(aggressivenessId),
      profileOverride: ProfileOverride.fromId(profileOverrideId),
      qualityMonitoringEnabled: qualityMonitoring ?? true,
      debugOverlay: debugOverlay ?? false,
      experimentalFeatures: experimental ?? false,
      fecEnabled: fecEnabled ?? false,
      fecProfile: FecProfile.fromId(fecProfileId),
      redundancyPercent: redundancyPercent ?? 10,
      adaptiveFecEnabled: adaptiveFecEnabled ?? true,
      opticalStreamSpeed: opticalStreamSpeed ?? 8.0,
      opticalStreamDensity: _validGridSize(opticalStreamDensity),
      opticalSyncAggressiveness: opticalSyncAggressiveness ?? 0.6,
      opticalRecoverySensitivity: opticalRecoverySensitivity ?? 0.5,
      opticalStreamDiagnostics: opticalStreamDiagnostics ?? true,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setInt(
      AppConstants.prefThemeMode,
      settings.themeMode.index,
    );
    await _prefs.setString(AppConstants.prefLanguage, settings.language);
    await _prefs.setBool(
      AppConstants.prefCompression,
      settings.compressionEnabled,
    );
    await _prefs.setString(
      AppConstants.prefCompressionMode,
      settings.compressionMode.id,
    );
    await _prefs.setBool(
      AppConstants.prefEncryption,
      settings.encryptionEnabled,
    );
    await _prefs.setString(
      AppConstants.prefTransferMode,
      settings.transferMode.id,
    );
    await _prefs.setBool(
      AppConstants.prefDiagnosticsEnabled,
      settings.diagnosticsEnabled,
    );
    await _prefs.setString(
      AppConstants.prefPreferredMethod,
      settings.preferredMethod.id,
    );
    await _prefs.setString(
      AppConstants.prefCameraResolution,
      settings.cameraResolution,
    );
    await _prefs.setInt(
      AppConstants.prefColorMatrixSize,
      settings.colorMatrixSize,
    );
    await _prefs.setDouble(
      AppConstants.prefColorTransferFrameRate,
      settings.colorTransferFrameRate,
    );
    await _prefs.setString(
      AppConstants.prefColorTransportQuality,
      settings.colorTransportQuality,
    );
    await _prefs.setInt(
      AppConstants.prefColorBitsPerChannel,
      settings.colorBitsPerChannel,
    );
    await _prefs.setBool(
      AppConstants.prefAdaptiveMode,
      settings.adaptiveModeEnabled,
    );
    await _prefs.setString(
      AppConstants.prefAdaptiveAggressiveness,
      settings.adaptiveAggressiveness.id,
    );
    await _prefs.setString(
      AppConstants.prefProfileOverride,
      settings.profileOverride.id,
    );
    await _prefs.setBool(
      AppConstants.prefQualityMonitoring,
      settings.qualityMonitoringEnabled,
    );
    await _prefs.setBool(
      AppConstants.prefDebugOverlay,
      settings.debugOverlay,
    );
    await _prefs.setBool(
      AppConstants.prefExperimentalFeatures,
      settings.experimentalFeatures,
    );
    await _prefs.setBool(AppConstants.prefFecEnabled, settings.fecEnabled);
    await _prefs.setString(
      AppConstants.prefFecProfile,
      settings.fecProfile.id,
    );
    await _prefs.setInt(
      AppConstants.prefRedundancyPercent,
      settings.redundancyPercent,
    );
    await _prefs.setBool(
      AppConstants.prefAdaptiveFecEnabled,
      settings.adaptiveFecEnabled,
    );
    await _prefs.setDouble(
      AppConstants.prefOpticalStreamSpeed,
      settings.opticalStreamSpeed,
    );
    await _prefs.setInt(
      AppConstants.prefOpticalStreamDensity,
      settings.opticalStreamDensity,
    );
    await _prefs.setDouble(
      AppConstants.prefOpticalSyncAggressiveness,
      settings.opticalSyncAggressiveness,
    );
    await _prefs.setDouble(
      AppConstants.prefOpticalRecoverySensitivity,
      settings.opticalRecoverySensitivity,
    );
    await _prefs.setBool(
      AppConstants.prefOpticalStreamDiagnostics,
      settings.opticalStreamDiagnostics,
    );
  }

  double? loadLastQualityScore() {
    return _prefs.getDouble(AppConstants.prefLastQualityScore);
  }

  Future<void> saveLastQualityScore(double score) async {
    await _prefs.setDouble(AppConstants.prefLastQualityScore, score);
  }

  TransferMethod _methodFromId(String? id) {
    if (id == null) return TransferMethod.qr;
    return TransferMethod.values.firstWhere(
      (m) => m.id == id,
      orElse: () => TransferMethod.qr,
    );
  }

  int _validGridSize(int? size) {
    if (size == 48) return 48;
    if (size == 32) return 32;
    if (size == 24) return 24;
    return 16;
  }

  int _validBitsPerChannel(int? bpc) {
    if (bpc == 1) return 1;
    if (bpc == 3) return 3;
    return 2;
  }
}
