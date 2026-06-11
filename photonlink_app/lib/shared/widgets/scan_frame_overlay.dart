import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../ui/colors.dart';
import '../../ui/motion.dart';

/// Camera scan framing overlay with corner brackets and animated scan line.
class ScanFrameOverlay extends StatelessWidget {
  const ScanFrameOverlay({
    super.key,
    this.frameSize = 260,
    this.label,
  });

  final double frameSize;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dimmed area outside the scan frame
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.45),
            BlendMode.srcOut,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: frameSize,
                  height: frameSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Corner brackets
        SizedBox(
          width: frameSize,
          height: frameSize,
          child: CustomPaint(
            painter: _CornerBracketPainter(
              color: AppColors.accent,
            ),
          ),
        ),

        // Animated scan line
        SizedBox(
          width: frameSize - 16,
          height: frameSize,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0),
                    AppColors.accent,
                    AppColors.accent.withValues(alpha: 0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                  begin: 0,
                  end: frameSize - 16,
                  duration: AppMotion.slow * 4,
                  curve: Curves.easeInOut,
                ),
          ),
        ),

        // Label below frame
        if (label != null)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.22,
            child: Text(
              label!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ),
      ],
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  _CornerBracketPainter({required this.color});

  final Color color;
  static const _length = 28.0;
  static const _stroke = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, _length)
        ..lineTo(0, 0)
        ..lineTo(_length, 0),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - _length, 0)
        ..lineTo(w, 0)
        ..lineTo(w, _length),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, h - _length)
        ..lineTo(0, h)
        ..lineTo(_length, h),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w - _length, h)
        ..lineTo(w, h)
        ..lineTo(w, h - _length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
