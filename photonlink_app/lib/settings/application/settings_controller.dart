import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../protocols/interfaces/compression_type.dart';
import '../../services/storage/preferences_service.dart';
import '../../transfer/scheduler/transfer_mode.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

/// Manages application settings state with persistence.
class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._repository) : super(_repository.load());

  final SettingsRepository _repository;

  Future<void> updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _repository.save(state);
  }

  Future<void> updateLanguage(String language) async {
    state = state.copyWith(language: language);
    await _repository.save(state);
  }

  Future<void> toggleCompression(bool enabled) async {
    state = state.copyWith(
      compressionEnabled: enabled,
      compressionMode:
          enabled ? CompressionType.gzip : CompressionType.none,
    );
    await _repository.save(state);
  }

  Future<void> updateCompressionMode(CompressionType mode) async {
    state = state.copyWith(
      compressionMode: mode,
      compressionEnabled: mode != CompressionType.none,
    );
    await _repository.save(state);
  }

  Future<void> toggleEncryption(bool enabled) async {
    state = state.copyWith(encryptionEnabled: enabled);
    await _repository.save(state);
  }

  Future<void> updateTransferMode(TransferMode mode) async {
    state = state.copyWith(transferMode: mode);
    await _repository.save(state);
  }

  Future<void> toggleDiagnostics(bool enabled) async {
    state = state.copyWith(diagnosticsEnabled: enabled);
    await _repository.save(state);
  }

  Future<void> updateCameraResolution(String resolution) async {
    state = state.copyWith(cameraResolution: resolution);
    await _repository.save(state);
  }

  Future<void> updateColorMatrixSize(int size) async {
    state = state.copyWith(colorMatrixSize: size);
    await _repository.save(state);
  }

  Future<void> updateColorTransferFrameRate(double fps) async {
    state = state.copyWith(colorTransferFrameRate: fps);
    await _repository.save(state);
  }

  Future<void> updateColorTransportQuality(String quality) async {
    state = state.copyWith(colorTransportQuality: quality);
    await _repository.save(state);
  }

  Future<void> toggleDebugOverlay(bool enabled) async {
    state = state.copyWith(debugOverlay: enabled);
    await _repository.save(state);
  }

  Future<void> toggleExperimentalFeatures(bool enabled) async {
    state = state.copyWith(experimentalFeatures: enabled);
    await _repository.save(state);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(preferencesServiceProvider));
});

final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController(ref.watch(settingsRepositoryProvider));
});

/// Alias for settings provider.
final settingsControllerProvider = settingsProvider;
