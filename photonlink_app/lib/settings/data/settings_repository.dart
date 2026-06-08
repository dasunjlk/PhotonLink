import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/transfer_method.dart';
import '../../services/storage/preferences_service.dart';
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

    return AppSettings(
      themeMode: themeIndex != null
          ? ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)]
          : ThemeMode.system,
      language: language ?? 'en',
      compressionEnabled: compression ?? false,
      compressionMode: CompressionType.fromId(compressionModeId),
      encryptionEnabled: encryption ?? false,
      transferMode: TransferMode.fromId(transferModeId),
      diagnosticsEnabled: diagnostics ?? true,
      preferredMethod: _methodFromId(methodId),
      cameraResolution: cameraResolution ?? 'high',
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
  }

  TransferMethod _methodFromId(String? id) {
    if (id == null) return TransferMethod.qr;
    return TransferMethod.values.firstWhere(
      (m) => m.id == id,
      orElse: () => TransferMethod.qr,
    );
  }
}
