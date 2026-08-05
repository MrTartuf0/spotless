import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/providers/searchbar_provider.dart';
import 'package:spotACrack/providers/ui_provider.dart';
import 'package:spotACrack/screens/home_feed.dart';
import 'package:spotACrack/screens/homepage.dart';
import 'package:spotACrack/screens/library_page.dart';
import 'package:spotACrack/utils/responsive.dart';
import 'package:spotACrack/widgets/bottom_player.dart';
import 'package:spotACrack/widgets/desktop/desktop_player_bar.dart';
import 'package:spotACrack/widgets/desktop/queue_panel.dart';
import 'package:spotACrack/widgets/desktop/side_nav.dart';

/// App frame. Wraps every route, so the navigation and the player stay put
/// while artist and album pages are pushed on top of the tabs.
///
/// Two shapes, chosen by window width rather than platform: a sidebar with a
/// wide player bar once there is room, and the phone layout (bottom nav with
/// the mini player docked above it) otherwise.
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  /// Moves to [index], first dropping any pushed page so the tab is visible.
  static void selectTab(BuildContext context, WidgetRef ref, int index) {
    final current = ref.read(selectedTabProvider);

    // Leaving search should give the keyboard back, otherwise the nav bar
    // stays hidden on the tab you just moved to.
    if (current == 1 && index != 1) {
      FocusScope.of(context).unfocus();
      ref.read(searchStateProvider.notifier).setKeyboardVisible(false);
    }

    if (GoRouterState.of(context).uri.path != '/') context.go('/');
    ref.read(selectedTabProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PlaybackShortcuts(
      child: context.isWide
          ? _DesktopFrame(child: child)
          : _MobileFrame(child: child),
    );
  }
}

/// The three tabs, kept alive in an [IndexedStack] so scroll position and
/// in-flight search results survive switching between them.
class TabHost extends ConsumerWidget {
  const TabHost({super.key});

  static const _tabs = [HomeFeed(), SearchPage(), LibraryPage()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IndexedStack(index: ref.watch(selectedTabProvider), children: _tabs);
  }
}

class _DesktopFrame extends ConsumerWidget {
  final Widget child;

  const _DesktopFrame({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The queue docks beside the content, but only where taking 320px off the
    // width still leaves a usable page.
    final showQueue = context.isExpanded && ref.watch(queuePanelOpenProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                SideNav(collapsed: context.breakpoint == Breakpoint.medium),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: const Color(0xFF121212),
                      child: child,
                    ),
                  ),
                ),
                if (showQueue) const QueuePanel(),
              ],
            ),
          ),
          const DesktopPlayerBar(),
        ],
      ),
    );
  }
}

class _MobileFrame extends ConsumerWidget {
  final Widget child;

  const _MobileFrame({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // While typing, hand the whole screen to the results.
    final keyboardVisible = ref.watch(searchStateProvider).isKeyboardVisible;
    final index = ref.watch(selectedTabProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: keyboardVisible
            ? const SizedBox(width: double.infinity)
            : LayoutBuilder(
                builder: (context, constraints) {
                  // Desktop windows are laid out at 1x1 for their first frame,
                  // where even the nav bar alone overflows. Below that, drop
                  // the player first and then the bar itself.
                  final room = constraints.maxHeight;
                  if (room < 72) return const SizedBox(width: double.infinity);
                  final roomForPlayer = room > 140;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (roomForPlayer) const BottomPlayer(),
                      _NavBar(
                        index: index,
                        onTap: (i) => AppShell.selectTab(context, ref, i),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// Space toggles playback, arrows scrub, Ctrl/Cmd + arrows change track.
///
/// Skipped while a text field has focus so typing a space in the search box
/// doesn't pause the music.
class _PlaybackShortcuts extends ConsumerWidget {
  final Widget child;

  const _PlaybackShortcuts({required this.child});

  static bool _isTyping() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    return context.widget is EditableText ||
        context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void nudge(int seconds) {
      final state = ref.read(audioPlayerProvider);
      if (state.currentTrackId.isEmpty) return;
      final target = state.currentPosition + Duration(seconds: seconds);
      ref.read(audioPlayerProvider.notifier).seekTo(
            target < Duration.zero
                ? Duration.zero
                : (target > state.totalDuration && state.totalDuration > Duration.zero
                    ? state.totalDuration
                    : target),
          );
    }

    final notifier = ref.read(audioPlayerProvider.notifier);

    void nudgeVolume(double delta) {
      notifier.setVolume(ref.read(audioPlayerProvider).volume + delta);
    }

    KeyEventResult handleKey(FocusNode node, KeyEvent event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }

      // Declining the event is the whole point: a key the framework reports as
      // handled is never forwarded to the platform's text input, so claiming
      // space here would stop it being typed into the search box.
      if (_isTyping()) return KeyEventResult.ignored;

      final keyboard = HardwareKeyboard.instance;
      final skipTrack = keyboard.isControlPressed || keyboard.isMetaPressed;

      switch (event.logicalKey) {
        case LogicalKeyboardKey.space:
          notifier.togglePlayPause();
        case LogicalKeyboardKey.arrowRight:
          skipTrack ? notifier.playNextTrack() : nudge(10);
        case LogicalKeyboardKey.arrowLeft:
          skipTrack ? notifier.playPreviousTrack() : nudge(-10);
        case LogicalKeyboardKey.arrowUp:
          nudgeVolume(0.05);
        case LogicalKeyboardKey.arrowDown:
          nudgeVolume(-0.05);
        case LogicalKeyboardKey.keyM:
          notifier.toggleMute();
        default:
          return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }

    // Sliders, buttons and text fields all see their keys first; this only
    // gets what they leave alone.
    return Focus(autofocus: true, onKeyEvent: handleKey, child: child);
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _NavBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF1F1F1F), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                selected: index == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.search_outlined,
                activeIcon: Icons.search,
                label: 'Search',
                selected: index == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.library_music_outlined,
                activeIcon: Icons.library_music,
                label: 'Library',
                selected: index == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white.withValues(alpha: 0.5);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        // Ripple on a bar this short reads as noise.
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: Icon(
                selected ? activeIcon : icon,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(height: 3),
            // Never wrap: mid-resize the bar is laid out at a fraction of a
            // pixel wide, and a wrapping label overflows the 58px bar.
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
