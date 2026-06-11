import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'photon_icon_button.dart';

/// A consistent top-left back affordance used on inner screens.
///
/// Pops the current route, falling back to the home route when there is
/// nothing to pop (e.g. deep links on desktop).
class PhotonBackButton extends StatelessWidget {
  const PhotonBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PhotonIconButton(
      icon: Icons.arrow_back_rounded,
      tooltip: 'Back',
      onPressed: onPressed ??
          () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
    );
  }
}
