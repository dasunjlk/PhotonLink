import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'models/capability_profile.dart';

/// Collects device capability signals for adaptive transfer.
class DeviceCapabilityDetector {
  DeviceCapabilityDetector({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;

  static const int _webCpuCoreEstimate = 4;

  Future<CapabilityProfile> detect({
    int cameraWidth = 0,
    int cameraHeight = 0,
    double cameraFpsEstimate = 0,
    String cameraResolutionPreset = 'high',
  }) async {
    final displays = PlatformDispatcher.instance.displays;
    final display = displays.isEmpty ? null : displays.first;
    final displayWidth = display?.size.width ?? 0;
    final displayHeight = display?.size.height ?? 0;
    final refreshRate = display?.refreshRate ?? 60;

    var cpuCores = _webCpuCoreEstimate;
    var cpuModel = 'unknown';
    var totalMemoryMb = 0;
    var platform = 'unknown';

    try {
      if (kIsWeb) {
        platform = 'web';
        final info = await _deviceInfo.webBrowserInfo;
        cpuModel = info.browserName.name;
      } else {
        cpuCores = Platform.numberOfProcessors;
        if (Platform.isAndroid) {
          platform = 'android';
          final info = await _deviceInfo.androidInfo;
          cpuModel = info.model;
          totalMemoryMb = 0;
        } else if (Platform.isIOS) {
          platform = 'ios';
          final info = await _deviceInfo.iosInfo;
          cpuModel = info.utsname.machine;
          totalMemoryMb = info.physicalRamSize;
        } else if (Platform.isWindows) {
          platform = 'windows';
          final info = await _deviceInfo.windowsInfo;
          cpuModel = info.computerName;
          totalMemoryMb = info.systemMemoryInMegabytes;
        } else if (Platform.isMacOS) {
          platform = 'macos';
          final info = await _deviceInfo.macOsInfo;
          cpuModel = info.model;
          totalMemoryMb = 0;
        } else if (Platform.isLinux) {
          platform = 'linux';
          final info = await _deviceInfo.linuxInfo;
          cpuModel = info.prettyName;
        }
      }
    } catch (_) {
      // Graceful degradation.
    }

    if (cameraWidth == 0 || cameraHeight == 0) {
      final est = _estimateCameraResolution(cameraResolutionPreset);
      cameraWidth = est.$1;
      cameraHeight = est.$2;
    }

    if (cameraFpsEstimate <= 0) {
      cameraFpsEstimate = cameraResolutionPreset == 'high' ? 30 : 24;
    }

    final deviceClass = kIsWeb
        ? DeviceClass.mid
        : _classifyDevice(
            cpuCores: cpuCores,
            memoryMb: totalMemoryMb,
            displayRefresh: refreshRate,
          );

    return CapabilityProfile(
      cameraWidth: cameraWidth,
      cameraHeight: cameraHeight,
      cameraFpsEstimate: cameraFpsEstimate,
      displayWidth: displayWidth,
      displayHeight: displayHeight,
      displayRefreshRate: refreshRate,
      cpuCores: cpuCores,
      cpuModel: cpuModel,
      totalMemoryMb: totalMemoryMb,
      deviceClass: deviceClass,
      platform: platform,
    );
  }

  (int, int) _estimateCameraResolution(String preset) {
    return preset == 'high' ? (1920, 1080) : (1280, 720);
  }

  DeviceClass _classifyDevice({
    required int cpuCores,
    required int memoryMb,
    required double displayRefresh,
  }) {
    var score = 0;
    if (cpuCores >= 8) {
      score += 2;
    } else if (cpuCores >= 4) {
      score += 1;
    }
    if (memoryMb >= 6000) {
      score += 2;
    } else if (memoryMb >= 3000) {
      score += 1;
    }
    if (displayRefresh >= 90) score += 1;

    if (score >= 4) return DeviceClass.high;
    if (score >= 2) return DeviceClass.mid;
    if (score >= 1) return DeviceClass.low;
    return DeviceClass.unknown;
  }
}
