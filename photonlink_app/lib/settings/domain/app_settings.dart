import 'package:flutter/material.dart';

import '../../protocols/transfer_method.dart';

/// Immutable application settings model.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = 'en',
    this.compressionEnabled = false,
    this.encryptionEnabled = false,
    this.preferredMethod = TransferMethod.qr,
    this.cameraResolution = 'high',
  });

  final ThemeMode themeMode;
  final String language;
  final bool compressionEnabled;
  final bool encryptionEnabled;
  final TransferMethod preferredMethod;
  final String cameraResolution;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? compressionEnabled,
    bool? encryptionEnabled,
    TransferMethod? preferredMethod,
    String? cameraResolution,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      compressionEnabled: compressionEnabled ?? this.compressionEnabled,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      preferredMethod: preferredMethod ?? this.preferredMethod,
      cameraResolution: cameraResolution ?? this.cameraResolution,
    );
  }
}
