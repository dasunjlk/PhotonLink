import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:photonlink_app/app.dart';
import 'package:photonlink_app/core/bootstrap.dart';
import 'package:photonlink_app/core/constants.dart';
import 'package:photonlink_app/features/home/home_screen.dart';
import 'package:photonlink_app/services/native_bridge/native_bridge_stub.dart';
import 'package:photonlink_app/services/native_bridge/native_bridge.dart';
import 'package:photonlink_app/services/storage/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PackageInfo packageInfo;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    packageInfo = PackageInfo(
      appName: 'PhotonLink',
      packageName: 'com.photonlink.app',
      version: '1.0.0',
      buildNumber: '1',
    );
  });

  List<Override> buildOverrides() => [
        preferencesServiceProvider.overrideWithValue(
          PreferencesService(prefs),
        ),
        packageInfoProvider.overrideWithValue(packageInfo),
        nativeBridgeProvider.overrideWithValue(NativeBridgeStub()),
      ];

  testWidgets('HomeScreen renders app title and transfer methods', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: buildOverrides(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('QR Transfer'), findsOneWidget);
    expect(find.text('Color Matrix'), findsOneWidget);
    expect(find.text('Optical Stream'), findsOneWidget);
  });

  testWidgets('PhotonLinkApp boots with router', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: buildOverrides(),
        child: const PhotonLinkApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text(AppConstants.appName), findsOneWidget);
  });
}
