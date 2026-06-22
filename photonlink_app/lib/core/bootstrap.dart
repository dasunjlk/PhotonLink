import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/core/core_backend.dart';
import '../services/core/core_providers.dart';
import '../services/core/impl/frb_core_api.dart';
import '../services/core/photon_link_core_api.dart';
import '../services/logger/app_logger.dart';
import '../services/native_bridge/native_bridge.dart';
import '../services/native_bridge/native_bridge_frb.dart';
import '../services/native_bridge/native_bridge_stub.dart';
import '../services/storage/preferences_service.dart';
import '../src/rust/frb_generated.dart' as frb;

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

    var backend = CoreBackend.dart;
    PhotonLinkNative nativeBridge = NativeBridgeStub();
    PhotonLinkCoreApi coreApi = const NotConnectedCoreApi();

    if (!kIsWeb) {
      try {
        await frb.PhotonLinkCoreApi.init();
        backend = CoreBackend.rust;
        nativeBridge = NativeBridgeFrb();
        coreApi = const FrbCoreApi();
        AppLogger.info('Rust core initialized (${await nativeBridge.coreVersion()})');
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Rust core unavailable, falling back to Dart backend: $error',
        );
        AppLogger.debug('Rust init stack', error, stackTrace);
      }
    }

    final pingResult = await nativeBridge.ping();
    AppLogger.info('Native bridge ping: $pingResult');

    return BootstrapResult(
      providerOverrides: [
        preferencesServiceProvider.overrideWithValue(
          PreferencesService(prefs),
        ),
        packageInfoProvider.overrideWithValue(packageInfo),
        nativeBridgeProvider.overrideWithValue(nativeBridge),
        backendProvider.overrideWithValue(backend),
        photonLinkCoreApiProvider.overrideWithValue(coreApi),
      ],
    );
  }
}

/// Provider for PackageInfo, overridden at bootstrap.
final packageInfoProvider = Provider<PackageInfo>(
  (ref) => throw UnimplementedError('PackageInfo not initialized'),
);
