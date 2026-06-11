import 'package:flutter/material.dart';

import '../../ui/radii.dart';

/// Fills all space given by the parent and clips optical content (QR, matrix,
/// camera) with rounded corners. The child should use [LayoutBuilder] or
/// [StackFit.expand] to consume the bounded area.
class OpticalViewport extends StatelessWidget {
  const OpticalViewport({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: AppRadii.lgRadius,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}

/// Returns the largest square side length that fits [constraints], minus
/// [padding] on each edge.
double opticalSquareSize(BoxConstraints constraints, {double padding = 0}) {
  final w = constraints.maxWidth;
  final h = constraints.maxHeight;
  if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
    return 0;
  }
  final innerW = w - padding * 2;
  final innerH = h - padding * 2;
  if (innerW <= 0 || innerH <= 0) return 0;
  return innerW < innerH ? innerW : innerH;
}
