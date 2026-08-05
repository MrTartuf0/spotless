import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Layout sizes the app adapts to.
///
/// These are window widths, not device types — a resized desktop window walks
/// down through them and the UI follows, which is also how the phone layout
/// gets exercised on desktop.
enum Breakpoint {
  /// Phones, and any window narrow enough that a sidebar would eat the content.
  compact,

  /// Tablets and half-screen desktop windows: icon rail instead of a sidebar.
  medium,

  /// Roomy desktop window: full sidebar, and space left over for the queue.
  expanded,
}

const double kMediumWidth = 760;
const double kExpandedWidth = 1160;

/// Widest the reading column ever gets. Beyond this, extra width becomes
/// margin instead of very long rows of text.
const double kMaxContentWidth = 1400;

extension ResponsiveContext on BuildContext {
  double get windowWidth => MediaQuery.sizeOf(this).width;

  Breakpoint get breakpoint {
    final width = windowWidth;
    if (width >= kExpandedWidth) return Breakpoint.expanded;
    if (width >= kMediumWidth) return Breakpoint.medium;
    return Breakpoint.compact;
  }

  /// True once there is room for side navigation — the whole desktop frame
  /// (sidebar + wide player bar) keys off this.
  bool get isWide => breakpoint != Breakpoint.compact;

  bool get isExpanded => breakpoint == Breakpoint.expanded;

  /// Horizontal page padding, wider on bigger windows so content doesn't sit
  /// flush against the sidebar.
  double get pagePadding => switch (breakpoint) {
    Breakpoint.compact => 16,
    Breakpoint.medium => 24,
    Breakpoint.expanded => 32,
  };

  /// Column count for artwork grids, derived from the available width so it
  /// keeps working at any window size rather than snapping at breakpoints.
  int gridColumns({double minTileWidth = 180}) {
    final usable = windowWidth - pagePadding * 2;
    final columns = (usable / minTileWidth).floor();
    return columns.clamp(2, 8);
  }

  /// Card edge for the horizontal rows on Home.
  double get mediaCardSize => switch (breakpoint) {
    Breakpoint.compact => 148,
    Breakpoint.medium => 164,
    Breakpoint.expanded => 180,
  };
}

/// Centers page content and caps how wide it can get.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = kMaxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Lets horizontal rows be dragged with a mouse, which is otherwise disabled
/// on desktop and makes the Home rows feel stuck.
class DragScrollBehavior extends MaterialScrollBehavior {
  const DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
