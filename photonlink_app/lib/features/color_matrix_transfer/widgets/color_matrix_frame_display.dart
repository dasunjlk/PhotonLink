import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/widgets/optical_viewport.dart';
import '../../../ui/spacing.dart';

/// Displays a color matrix frame raster as an image.
///
/// When [size] is null the matrix expands to fill the parent [OpticalViewport].
class ColorMatrixFrameDisplay extends StatelessWidget {
  const ColorMatrixFrameDisplay({
    this.rasterBytes,
    this.size,
    super.key,
  });

  final Uint8List? rasterBytes;

  /// Fixed edge length. When null, expands to the largest square that fits.
  final double? size;

  @override
  Widget build(BuildContext context) {
    if (size != null) {
      return _buildContent(context, size!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final edge = opticalSquareSize(
          constraints,
          padding: AppSpacing.sm,
        );
        if (edge <= 0) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(child: _buildContent(context, edge));
      },
    );
  }

  Widget _buildContent(BuildContext context, double edge) {
    final scheme = Theme.of(context).colorScheme;

    if (rasterBytes == null || rasterBytes!.isEmpty) {
      return Container(
        width: edge,
        height: edge,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline),
        ),
        child: Center(
          child: Icon(
            Icons.grid_view_rounded,
            size: 64,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Container(
        width: edge,
        height: edge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            rasterBytes!,
            key: ValueKey(rasterBytes!.hashCode),
            width: edge,
            height: edge,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
