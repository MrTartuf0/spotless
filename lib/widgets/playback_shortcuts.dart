import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';

/// The keyboard transport. The dedicated media keys (Fn+F7/F8/F9 on most
/// laptops) play/pause and change track; space toggles playback, arrows scrub
/// and change volume, Ctrl/Cmd + left and right change track, M mutes. With
/// [dismissible], Escape closes the route this is mounted in.
///
/// The media keys only arrive while the window has focus. Reaching them with
/// the app in the background needs the OS media session — [MediaSession] on
/// Android and iOS, and nothing on desktop yet.
///
/// Mounted once around the app frame, and again inside every modal: a route
/// pushed on top owns focus, so the frame's copy stops seeing keys the moment a
/// sheet opens. Nesting is harmless — only the innermost focused one runs.
class PlaybackShortcuts extends ConsumerWidget {
  final Widget child;

  /// Whether Escape should pop. Off for the app frame, which has nothing to
  /// pop to, and on for anything presented over it.
  final bool dismissible;

  const PlaybackShortcuts({
    super.key,
    required this.child,
    this.dismissible = false,
  });

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
      ref
          .read(audioPlayerProvider.notifier)
          .seekTo(
            target < Duration.zero
                ? Duration.zero
                : (target > state.totalDuration &&
                        state.totalDuration > Duration.zero
                    ? state.totalDuration
                    : target),
          );
    }

    final notifier = ref.read(audioPlayerProvider.notifier);

    void nudgeVolume(double delta) {
      notifier.setVolume(ref.read(audioPlayerProvider).volume + delta);
    }

    // The dedicated transport keys — Fn+F7/F8/F9 on most laptops, the XF86Audio
    // keysyms on Linux. Handled ahead of the typing guard below, because
    // unlike space they are not text and are meant to work from anywhere,
    // search box included.
    bool handleMediaKey(LogicalKeyboardKey key) {
      final playing = ref.read(audioPlayerProvider).isPlaying;

      switch (key) {
        case LogicalKeyboardKey.mediaPlayPause:
          notifier.togglePlayPause();
        // Some keyboards and remotes send discrete play and pause rather than
        // the combined key, so acting on either unconditionally would toggle
        // the wrong way.
        case LogicalKeyboardKey.mediaPlay:
          if (!playing) notifier.togglePlayPause();
        case LogicalKeyboardKey.mediaPause:
        case LogicalKeyboardKey.mediaStop:
          if (playing) notifier.togglePlayPause();
        case LogicalKeyboardKey.mediaTrackNext:
          notifier.playNextTrack();
        case LogicalKeyboardKey.mediaTrackPrevious:
          notifier.playPreviousTrack();
        case LogicalKeyboardKey.mediaFastForward:
          nudge(10);
        case LogicalKeyboardKey.mediaRewind:
          nudge(-10);
        default:
          // Volume and mute keys are left to the OS, which is already
          // adjusting the system output they belong to.
          return false;
      }
      return true;
    }

    KeyEventResult handleKey(FocusNode node, KeyEvent event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }

      if (handleMediaKey(event.logicalKey)) return KeyEventResult.handled;

      // Declining the event is the whole point: a key the framework reports as
      // handled is never forwarded to the platform's text input, so claiming
      // space here would stop it being typed into the search box.
      if (_isTyping()) return KeyEventResult.ignored;

      final keyboard = HardwareKeyboard.instance;
      final skipTrack = keyboard.isControlPressed || keyboard.isMetaPressed;

      switch (event.logicalKey) {
        case LogicalKeyboardKey.escape:
          // Left alone when there is nothing to close, so the framework's own
          // dismiss handling still gets a look at it.
          if (!dismissible) return KeyEventResult.ignored;
          Navigator.of(context).maybePop();
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

/// Shortcut hints for tooltips. Meta reads as Cmd on Apple platforms and Ctrl
/// everywhere else, matching what [PlaybackShortcuts] accepts.
String shortcutHint(BuildContext context, String key) {
  return switch (Theme.of(context).platform) {
    TargetPlatform.macOS || TargetPlatform.iOS => '⌘$key',
    _ => 'Ctrl+$key',
  };
}
