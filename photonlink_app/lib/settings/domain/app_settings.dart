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
    this.colorMatrixSize = 24,
    this.colorTransferFrameRate = 4.0,
    this.colorTransportQuality = 'balanced',
    this.debugOverlay = false,
    this.experimentalFeatures = false,
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
  final int colorMatrixSize;
  final double colorTransferFrameRate;
  final String colorTransportQuality;
  final bool debugOverlay;
  final bool experimentalFeatures;

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
      compressionMode: compressionMode ?? this.compressionMode,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      transferMode: transferMode ?? this.transferMode,
      diagnosticsEnabled: diagnosticsEnabled ?? this.diagnosticsEnabled,
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
