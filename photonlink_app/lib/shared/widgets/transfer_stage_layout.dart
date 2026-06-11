import 'package:flutter/material.dart';

import '../../ui/responsive.dart';
import '../../ui/spacing.dart';
import 'optical_viewport.dart';

/// Two-pane layout for the Transfer screen: the optical [display] on the
/// left and the [info] panel (plus optional [controls]) on the right.
///
/// Must live inside a bounded-height parent (typically [Expanded]). Content is
/// sized to fit the viewport — no page scrolling.
class TransferStageLayout extends StatelessWidget {
  const TransferStageLayout({
    required this.display,
    required this.info,
    super.key,
    this.controls,
    this.banner,
  });

  final Widget display;
  final Widget info;
  final Widget? controls;

  /// Optional full-width banner shown above both panes (e.g. resume prompt).
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (wide) {
            return _WideLayout(
              maxHeight: constraints.maxHeight,
              display: display,
              info: info,
              controls: controls,
              banner: banner,
            );
          }
          return _NarrowLayout(
            maxHeight: constraints.maxHeight,
            display: display,
            info: info,
            controls: controls,
            banner: banner,
          );
        },
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.maxHeight,
    required this.display,
    required this.info,
    this.controls,
    this.banner,
  });

  final double maxHeight;
  final Widget display;
  final Widget info;
  final Widget? controls;
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (banner != null) ...[
          banner!,
          const SizedBox(height: AppSpacing.sm),
        ],
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: OpticalViewport(child: display),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 2,
                child: _SidePanel(info: info, controls: controls),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.maxHeight,
    required this.display,
    required this.info,
    this.controls,
    this.banner,
  });

  final double maxHeight;
  final Widget display;
  final Widget info;
  final Widget? controls;
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (banner != null) ...[
          banner!,
          const SizedBox(height: AppSpacing.sm),
        ],
        Expanded(
          flex: 5,
          child: OpticalViewport(child: display),
        ),
        const SizedBox(height: AppSpacing.sm),
        Flexible(
          flex: 4,
          fit: FlexFit.tight,
          child: _SidePanel(info: info, controls: controls),
        ),
      ],
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.info, this.controls});

  final Widget info;
  final Widget? controls;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: info),
        if (controls != null) ...[
          const SizedBox(height: AppSpacing.sm),
          controls!,
        ],
      ],
    );
  }
}
