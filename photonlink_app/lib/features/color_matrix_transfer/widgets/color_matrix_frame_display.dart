import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Displays a color matrix frame raster as an image.
class ColorMatrixFrameDisplay extends StatelessWidget {
  const ColorMatrixFrameDisplay({
    this.rasterBytes,
    this.size = 280,
    super.key,
  });

  final Uint8List? rasterBytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (rasterBytes == null || rasterBytes!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(
          child: Icon(Icons.grid_view_rounded, size: 64, color: Colors.white38),
        ),
      );
    }

    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
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
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
