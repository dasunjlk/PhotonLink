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
    this.colorMatrixSize = 16,
    this.colorTransferFrameRate = 4.0,
    this.colorTransportQuality = 'balanced',
    this.debugOverlay = false,
    this.experimentalFeatures = false,
  });

  final ThemeMode themeMode;
  final String language;
  final bool compressionEnabled;
  final bool encryptionEnabled;
  final TransferMethod preferredMethod;
  final String cameraResolution;
  final int colorMatrixSize;
  final double colorTransferFrameRate;
  final String colorTransportQuality;
  final bool debugOverlay;
  final bool experimentalFeatures;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? compressionEnabled,
    bool? encryptionEnabled,
    TransferMethod? preferredMethod,
    String? cameraResolution,
    int? colorMatrixSize,
    double? colorTransferFrameRate,
    String? colorTransportQuality,
    bool? debugOverlay,
    bool? experimentalFeatures,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      compressionEnabled: compressionEnabled ?? this.compressionEnabled,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      preferredMethod: preferredMethod ?? this.preferredMethod,
      cameraResolution: cameraResolution ?? this.cameraResolution,
      colorMatrixSize: colorMatrixSize ?? this.colorMatrixSize,
      colorTransferFrameRate:
          colorTransferFrameRate ?? this.colorTransferFrameRate,
      colorTransportQuality:
          colorTransportQuality ?? this.colorTransportQuality,
      debugOverlay: debugOverlay ?? this.debugOverlay,
      experimentalFeatures: experimentalFeatures ?? this.experimentalFeatures,
    );
  }
}
