import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/logger/app_logger.dart';
import '../../services/native_bridge/native_bridge.dart';
import '../../services/native_bridge/native_bridge_stub.dart';
import '../../services/storage/preferences_service.dart';

/// Result of async application bootstrap.
class BootstrapResult {
  const BootstrapResult({required this.providerOverrides});

  final List<Override> providerOverrides;
}

/// Initializes core services before the app widget tree mounts.
abstract final class Bootstrap {
  static Future<BootstrapResult> init() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();

    AppLogger.init();
    AppLogger.info('PhotonLink bootstrap starting…');
    AppLogger.info('App version: ${packageInfo.version}+${packageInfo.buildNumber}');

    final nativeBridge = NativeBridgeStub();
    final pingResult = await nativeBridge.ping();
    AppLogger.info('Native bridge ping: $pingResult');

    return BootstrapResult(
      providerOverrides: [
        preferencesServiceProvider.overrideWithValue(
          PreferencesService(prefs),
        ),
        packageInfoProvider.overrideWithValue(packageInfo),
        nativeBridgeProvider.overrideWithValue(nativeBridge),
      ],
    );
  }
}

/// Provider for PackageInfo, overridden at bootstrap.
final packageInfoProvider = Provider<PackageInfo>(
  (ref) => throw UnimplementedError('PackageInfo not initialized'),
);
