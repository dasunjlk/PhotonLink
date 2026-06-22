import 'package:flutter/material.dart';

import '../../protocols/transfer_method.dart';
import '../../transfer/adaptive/models/transport_profile.dart';
import '../../transfer/fec/models/fec_profile.dart';
import '../../transfer/scheduler/transfer_mode.dart';
import '../../protocols/interfaces/compression_type.dart';

/// Immutable application settings model.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
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
    this.colorBitsPerChannel = 2,
    this.adaptiveModeEnabled = true,
    this.adaptiveAggressiveness = AdaptiveAggressiveness.normal,
    this.profileOverride = ProfileOverride.auto,
    this.qualityMonitoringEnabled = true,
    this.debugOverlay = false,
    this.experimentalFeatures = false,
    this.fecEnabled = false,
    this.fecProfile = FecProfile.balanced,
    this.redundancyPercent = 10,
    this.adaptiveFecEnabled = true,
    this.opticalStreamSpeed = 8.0,
    this.opticalStreamDensity = 24,
    this.opticalSyncAggressiveness = 0.6,
    this.opticalRecoverySensitivity = 0.5,
    this.opticalStreamDiagnostics = true,
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
  final int colorBitsPerChannel;
  final bool adaptiveModeEnabled;
  final AdaptiveAggressiveness adaptiveAggressiveness;
  final ProfileOverride profileOverride;
  final bool qualityMonitoringEnabled;
  final bool debugOverlay;
  final bool experimentalFeatures;
  final bool fecEnabled;
  final FecProfile fecProfile;
  final int redundancyPercent;
  final bool adaptiveFecEnabled;
  final double opticalStreamSpeed;
  final int opticalStreamDensity;
  final double opticalSyncAggressiveness;
  final double opticalRecoverySensitivity;
  final bool opticalStreamDiagnostics;

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
    int? colorBitsPerChannel,
    bool? adaptiveModeEnabled,
    AdaptiveAggressiveness? adaptiveAggressiveness,
    ProfileOverride? profileOverride,
    bool? qualityMonitoringEnabled,
    bool? debugOverlay,
    bool? experimentalFeatures,
    bool? fecEnabled,
    FecProfile? fecProfile,
    int? redundancyPercent,
    bool? adaptiveFecEnabled,
    double? opticalStreamSpeed,
    int? opticalStreamDensity,
    double? opticalSyncAggressiveness,
    double? opticalRecoverySensitivity,
    bool? opticalStreamDiagnostics,
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
      colorBitsPerChannel: colorBitsPerChannel ?? this.colorBitsPerChannel,
      adaptiveModeEnabled: adaptiveModeEnabled ?? this.adaptiveModeEnabled,
      adaptiveAggressiveness:
          adaptiveAggressiveness ?? this.adaptiveAggressiveness,
      profileOverride: profileOverride ?? this.profileOverride,
      qualityMonitoringEnabled:
          qualityMonitoringEnabled ?? this.qualityMonitoringEnabled,
      debugOverlay: debugOverlay ?? this.debugOverlay,
      experimentalFeatures: experimentalFeatures ?? this.experimentalFeatures,
      fecEnabled: fecEnabled ?? this.fecEnabled,
      fecProfile: fecProfile ?? this.fecProfile,
      redundancyPercent: redundancyPercent ?? this.redundancyPercent,
      adaptiveFecEnabled: adaptiveFecEnabled ?? this.adaptiveFecEnabled,
      opticalStreamSpeed: opticalStreamSpeed ?? this.opticalStreamSpeed,
      opticalStreamDensity: opticalStreamDensity ?? this.opticalStreamDensity,
      opticalSyncAggressiveness:
          opticalSyncAggressiveness ?? this.opticalSyncAggressiveness,
      opticalRecoverySensitivity:
          opticalRecoverySensitivity ?? this.opticalRecoverySensitivity,
      opticalStreamDiagnostics:
          opticalStreamDiagnostics ?? this.opticalStreamDiagnostics,
    );
  }
}
