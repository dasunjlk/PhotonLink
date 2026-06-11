import 'package:flutter/widgets.dart';

/// Responsive breakpoints and helpers for adaptive layouts.
///
/// PhotonLink targets Android, Windows, Linux, and macOS, so layouts must
/// scale from a narrow phone (stacked) up to a wide desktop (multi-column).
abstract final class Breakpoints {
  /// Below this width we treat the device as a compact phone layout.
  static const double mobile = 600;

  /// Below this width we treat the device as a medium / tablet layout.
  static const double tablet = 905;

  /// At or above [tablet] we render expansive multi-column desktop layouts.
  static const double desktop = 1240;
}

enum ScreenSize { mobile, tablet, desktop }

/// Convenience responsive helpers on [BuildContext].
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  ScreenSize get screenSize {
    final w = screenWidth;
    if (w < Breakpoints.mobile) return ScreenSize.mobile;
    if (w < Breakpoints.tablet) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isTablet => screenSize == ScreenSize.tablet;
  bool get isDesktop => screenSize == ScreenSize.desktop;

  /// True when there is enough width for side-by-side (two-pane) layouts.
  bool get isWide => screenWidth >= Breakpoints.tablet;

  /// Picks a value based on the current breakpoint, falling back gracefully.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    switch (screenSize) {
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.mobile:
        return mobile;
    }
  }
}
