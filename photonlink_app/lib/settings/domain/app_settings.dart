import 'package:flutter/material.dart';

import '../../protocols/transfer_method.dart';
import '../../transfer/scheduler/transfer_mode.dart';
import '../../protocols/interfaces/compression_type.dart';

/// Immutable application settings model.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = 'en',
    this.compressionEnabled = false,
    this.compressionMode = CompressionType.none,
    this.encryptionEnabled = false,
    this.transferMode = TransferMode.normal,
    this.diagnosticsEnabled = true,
    this.preferredMethod = TransferMethod.qr,
    this.cameraResolution = 'high',
  });

  final ThemeMode themeMode;
  final String language;
  final bool compressionEnabled;
  final CompressionType compressionMode;
  final bool encryptionEnabled;
  final TransferMode transferMode;
  final bool diagnosticsEnabled;
  final TransferMethod preferredMethod;
  final String cameraResolution;

  CompressionType get effectiveCompression =>
      compressionEnabled ? compressionMode : CompressionType.none;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? compressionEnabled,
    CompressionType? compressionMode,
    bool? encryptionEnabled,
    TransferMode? transferMode,
    bool? diagnosticsEnabled,
    TransferMethod? preferredMethod,
    String? cameraResolution,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      compressionEnabled: compressionEnabled ?? this.compressionEnabled,
      compressionMode: compressionMode ?? this.compressionMode,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      transferMode: transferMode ?? this.transferMode,
      diagnosticsEnabled: diagnosticsEnabled ?? this.diagnosticsEnabled,
      preferredMethod: preferredMethod ?? this.preferredMethod,
      cameraResolution: cameraResolution ?? this.cameraResolution,
    );
  }
}
