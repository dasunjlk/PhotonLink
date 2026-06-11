import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../shared/widgets/optical_viewport.dart';
import '../../../ui/spacing.dart';

/// Displays a single QR frame with high error correction.
/// Isolated to limit rebuild scope when parent updates frequently.
///
/// When [size] is null the QR expands to fill the parent [OpticalViewport].
class QrFrameDisplay extends StatelessWidget {
  const QrFrameDisplay({
    required this.data,
    this.size,
    super.key,
  });

  final String? data;

  /// Fixed edge length. When null, expands to the largest square that fits.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (size != null) {
      return _buildContent(theme, size!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final edge = opticalSquareSize(
          constraints,
          padding: AppSpacing.md,
        );
        if (edge <= 0) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(child: _buildContent(theme, edge));
      },
    );
  }

  Widget _buildContent(ThemeData theme, double edge) {
    if (data == null || data!.isEmpty) {
      return Container(
        width: edge,
        height: edge,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Waiting for frame…'),
      );
    }

    final qrSize = math.max(edge - AppSpacing.md * 2, 48).toDouble();

    return RepaintBoundary(
      child: Container(
        width: edge,
        height: edge,
        alignment: Alignment.center,
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
          size: qrSize,
          gapless: true,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
