import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../ui/spacing.dart';

/// Displays a single QR frame with high error correction.
/// Isolated to limit rebuild scope when parent updates frequently.
class QrFrameDisplay extends StatelessWidget {
  const QrFrameDisplay({
    required this.data,
    this.size = 280,
    super.key,
  });

  final String? data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data == null || data!.isEmpty) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Waiting for frame…'),
      );
    }

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: QrImageView(
          key: ValueKey(data),
          data: data!,
          version: QrVersions.auto,
          size: size,
          gapless: true,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
