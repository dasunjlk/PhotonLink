import 'package:flutter/material.dart';

import '../../ui/colors.dart';

/// Supported optical transfer methods.
enum TransferMethod {
  qr(
    id: 'qr',
    displayName: 'QR Transfer',
    description: 'Encode files as scannable QR code sequences',
    icon: Icons.qr_code_2_rounded,
    accentColor: AppColors.qrAccent,
    isAvailable: true,
  ),
  colorMatrix(
    id: 'color_matrix',
    displayName: 'Color Matrix',
    description: 'High-density color grid data encoding',
    icon: Icons.grid_view_rounded,
    accentColor: AppColors.colorMatrixAccent,
    isAvailable: true,
  ),
  opticalStream(
    id: 'optical_stream',
    displayName: 'Optical Stream',
    description: 'Continuous visual frame streaming',
    icon: Icons.videocam_rounded,
    accentColor: AppColors.opticalStreamAccent,
    isAvailable: false,
    isPreview: true,
  ),
  audio(
    id: 'audio',
    displayName: 'Audio Transfer',
    description: 'Acoustic data transmission (future)',
    icon: Icons.graphic_eq_rounded,
    accentColor: AppColors.audioAccent,
    isAvailable: false,
  ),
  flash(
    id: 'flash',
    displayName: 'Flash Transfer',
    description: 'LED strobe data transmission (future)',
    icon: Icons.flash_on_rounded,
    accentColor: AppColors.flashAccent,
    isAvailable: false,
  );

  const TransferMethod({
    required this.id,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.isAvailable = true,
    this.isPreview = false,
  });

  final String id;
  final String displayName;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isAvailable;
  final bool isPreview;

  /// URL-safe route segment for go_router.
  String get routeName => id.replaceAll('_', '-');

  /// Resolves a route name back to a TransferMethod, defaulting to QR.
  static TransferMethod fromRouteName(String name) {
    final normalized = name.replaceAll('-', '_');
    return TransferMethod.values.firstWhere(
      (m) => m.id == normalized,
      orElse: () => TransferMethod.qr,
    );
  }

  /// Methods shown on the home screen.
  static List<TransferMethod> get homeMethods => [
        TransferMethod.qr,
        TransferMethod.colorMatrix,
        TransferMethod.opticalStream,
      ];
}
