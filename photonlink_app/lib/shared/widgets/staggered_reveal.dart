import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../ui/motion.dart';

/// Wraps children with staggered fade-and-slide entry animations.
class StaggeredReveal extends StatelessWidget {
  const StaggeredReveal({
    required this.children,
    super.key,
    this.delay = Duration.zero,
  });

  final List<Widget> children;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          children[i]
              .animate(
                delay: delay + AppMotion.stagger * i,
              )
              .fadeIn(duration: AppMotion.normal, curve: AppMotion.enter)
              .slideY(
                begin: 0.15,
                end: 0,
                duration: AppMotion.normal,
                curve: AppMotion.enter,
              ),
      ],
    );
  }
}
