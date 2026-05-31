import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await Bootstrap.init();
  runApp(
    ProviderScope(
      overrides: bootstrap.providerOverrides,
      child: const PhotonLinkApp(),
    ),
  );
}
