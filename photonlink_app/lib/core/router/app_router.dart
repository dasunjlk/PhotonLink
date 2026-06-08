import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/about_screen.dart';
import '../../features/camera_scan/camera_scan_screen.dart';
import '../../features/file_picker/file_picker_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/color_matrix_transfer/color_matrix_completion_screen.dart';
import '../../features/color_matrix_transfer/color_matrix_receiver_screen.dart';
import '../../features/color_matrix_transfer/color_matrix_sender_screen.dart';
import '../../features/qr_transfer/qr_completion_screen.dart';
import '../../features/qr_transfer/qr_receiver_screen.dart';
import '../../features/qr_transfer/qr_sender_screen.dart';
import '../../features/transfer_setup/transfer_setup_screen.dart';
import '../../transfer/application/color_matrix_transfer_state.dart';
import '../../transfer/application/transfer_state.dart';
import '../../history/presentation/history_screen.dart';
import '../../protocols/transfer_method.dart';
import '../../settings/presentation/settings_screen.dart';

/// Route path constants — single source of truth for navigation paths.
abstract final class AppRoutes {
  static const home = '/';
  static const transferSetup = '/transfer/:method';
  static const scan = '/scan';
  static const pick = '/pick';
  static const settings = '/settings';
  static const history = '/history';
  static const about = '/about';
  static const qrSend = '/qr/send';
  static const qrReceive = '/qr/receive';
  static const qrComplete = '/qr/complete';
  static const colorMatrixSend = '/color-matrix/send';
  static const colorMatrixReceive = '/color-matrix/receive';
  static const colorMatrixComplete = '/color-matrix/complete';

  static String transferSetupPath(TransferMethod method) =>
      '/transfer/${method.routeName}';
}

/// Global navigator key for imperative navigation when needed.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// go_router configuration provider.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.transferSetup,
        name: 'transferSetup',
        builder: (context, state) {
          final methodName = state.pathParameters['method'] ?? 'qr';
          final method = TransferMethod.fromRouteName(methodName);
          return TransferSetupScreen(method: method);
        },
      ),
      GoRoute(
        path: AppRoutes.scan,
        name: 'scan',
        builder: (context, state) {
          final methodName = state.uri.queryParameters['method'] ?? 'qr';
          final method = TransferMethod.fromRouteName(methodName);
          return CameraScanScreen(method: method);
        },
      ),
      GoRoute(
        path: AppRoutes.pick,
        name: 'pick',
        builder: (context, state) {
          final methodName = state.uri.queryParameters['method'] ?? 'qr';
          final method = TransferMethod.fromRouteName(methodName);
          return FilePickerScreen(method: method);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.qrSend,
        name: 'qrSend',
        builder: (context, state) => const QrSenderScreen(),
      ),
      GoRoute(
        path: AppRoutes.qrReceive,
        name: 'qrReceive',
        builder: (context, state) => const QrReceiverScreen(),
      ),
      GoRoute(
        path: AppRoutes.qrComplete,
        name: 'qrComplete',
        builder: (context, state) {
          final receiverState = state.extra as ReceiverTransferState?;
          return QrCompletionScreen(
            state: receiverState ?? const ReceiverTransferState(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.colorMatrixSend,
        name: 'colorMatrixSend',
        builder: (context, state) => const ColorMatrixSenderScreen(),
      ),
      GoRoute(
        path: AppRoutes.colorMatrixReceive,
        name: 'colorMatrixReceive',
        builder: (context, state) => const ColorMatrixReceiverScreen(),
      ),
      GoRoute(
        path: AppRoutes.colorMatrixComplete,
        name: 'colorMatrixComplete',
        builder: (context, state) {
          final receiverState = state.extra as ColorMatrixReceiverState?;
          return ColorMatrixCompletionScreen(
            state: receiverState ?? const ColorMatrixReceiverState(),
          );
        },
      ),
    ],
  );
});
