import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/providers/audio_player/audio_player_state.dart';
import 'package:spotACrack/utils/responsive.dart';
import 'package:spotACrack/widgets/artist_link.dart';
import 'package:spotACrack/widgets/lyrics_view.dart';
import 'package:spotACrack/widgets/playback_shortcuts.dart';
import 'package:spotACrack/widgets/queue_list.dart';
import 'package:spotACrack/widgets/up_next_sheet.dart';
import 'package:spotACrack/widgets/volume_control.dart';

/// Full-window "Now Playing" for desktop: large artwork and full-size
/// transport, with lyrics and the queue beside it when the window is wide
/// enough, or reachable from buttons when it isn't.
///
/// Everything is laid out against the live window size (via [LayoutBuilder])
/// and scrolls rather than clipping, so it reflows as the window resizes and
/// never cuts content off at small sizes.
class DesktopNowPlaying extends ConsumerWidget {
  const DesktopNowPlaying({super.key});

  /// Below this the side panel (lyrics/queue) can't fit beside the player, so
  /// it collapses to buttons that open sheets instead.
  static const double _sidePanelMinWidth = 900;

  /// Opens it as an opaque full-window overlay that slides up over the app,
  /// player bar included, for a focused listening mode. Escape, the collapse
  /// chevron, or a downward drag dismisses it.
  static Future<void> open(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Now playing',
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const DesktopNowPlaying(),
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(audioPlayerProvider.select((s) => s.dominantColor));
    final album = ref.watch(
      audioPlayerProvider.select((s) => s.currentAlbumName),
    );

    // Escape closes, and the transport keys keep working here rather than
    // stopping at the frame underneath.
    return PlaybackShortcuts(
      dismissible: true,
      child: _DragDownToDismiss(
        onDismiss: () => Navigator.of(context).maybePop(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(color.withValues(alpha: 0.7), Colors.black),
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _Header(album: album),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final sideBySide =
                            constraints.maxWidth >= _sidePanelMinWidth;

                        if (sideBySide) {
                          return const Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _PlayerPane(compactActions: false),
                              ),
                              VerticalDivider(
                                width: 1,
                                color: Color(0x1AFFFFFF),
                              ),
                              Expanded(flex: 4, child: _SidePanel()),
                            ],
                          );
                        }

                        // Narrow: player only, with lyrics/queue reachable
                        // from the action row.
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: const _PlayerPane(compactActions: true),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String album;

  const _Header({required this.album});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Collapse (Esc)',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.keyboard_arrow_down),
            color: Colors.white,
            iconSize: 28,
          ),
          Expanded(
            child: Text(
              album.isEmpty ? 'Now playing' : album,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Artwork, track info and the full transport, centred and scrollable so it
/// never clips when the window is short.
///
/// [compactActions] adds Lyrics and Queue buttons for the narrow layout, where
/// there is no side panel to hold them.
class _PlayerPane extends ConsumerWidget {
  final bool compactActions;

  const _PlayerPane({required this.compactActions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioPlayerProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Artwork tracks whichever dimension is tighter, so a short or a
        // narrow window both keep it fully visible. Computed with min/max
        // rather than chained clamp(), whose bounds can invert on a tiny
        // window and throw.
        var art = (constraints.maxWidth * 0.6).clamp(140.0, 420.0).toDouble();
        final byHeight = constraints.maxHeight * 0.5;
        if (byHeight > 120 && art > byHeight) art = byHeight;
        final controlsWidth = (art + 40).clamp(240.0, constraints.maxWidth);

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Artwork(imageUrl: state.currentTrackImage, size: art),
                  const SizedBox(height: 28),
                  _TrackInfo(state: state),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: controlsWidth),
                    child: Column(
                      children: [
                        _SeekBar(state: state),
                        const SizedBox(height: 8),
                        // Scale the transport down rather than let it clip on a
                        // very narrow window.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _Controls(state: state),
                        ),
                        const SizedBox(height: 16),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _BottomActions(
                            liked: state.isLiked,
                            showSideAccess: compactActions,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Like, volume, and — on the narrow layout — Lyrics/Queue openers.
class _BottomActions extends ConsumerWidget {
  final bool liked;
  final bool showSideAccess;

  const _BottomActions({required this.liked, required this.showSideAccess});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: liked ? 'Remove from liked' : 'Add to liked',
          onPressed: () => ref.read(audioPlayerProvider.notifier).toggleLike(),
          icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
          color: liked ? const Color(0xff1BD760) : const Color(0xB3FFFFFF),
          iconSize: 22,
        ),
        const SizedBox(width: 4),
        const VolumeControl(sliderWidth: 130),
        if (showSideAccess) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Lyrics',
            onPressed: () => _openSheet(context, const LyricsSheet()),
            icon: const Icon(Icons.lyrics_outlined, size: 21),
            color: const Color(0xB3FFFFFF),
          ),
          IconButton(
            tooltip: 'Queue',
            onPressed: () => _openSheet(context, const UpNextSheet()),
            icon: const Icon(Icons.queue_music, size: 21),
            color: const Color(0xB3FFFFFF),
          ),
        ],
      ],
    );
  }

  void _openSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => sheet,
    );
  }
}

class _TrackInfo extends StatelessWidget {
  final AudioPlayerState state;

  const _TrackInfo({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          state.currentTrackTitle.isEmpty ? 'Song' : state.currentTrackTitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        ArtistLink(
          artistId: state.currentArtistId,
          artistName: state.currentTrackArtist,
          // Close Now Playing before navigating to the artist page underneath.
          onBeforeNavigate: () => Navigator.of(context).maybePop(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _Artwork({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child:
            imageUrl.startsWith('http')
                ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: context.cachePx(size),
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
                : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF2A2A2A),
    child: Icon(Icons.music_note, size: size * 0.3, color: Colors.white38),
  );
}

/// Drag-tracked seek bar. While dragging it shows the dragged position rather
/// than the playback position, so the thumb doesn't fight the position stream.
class _SeekBar extends ConsumerStatefulWidget {
  final AudioPlayerState state;

  const _SeekBar({required this.state});

  @override
  ConsumerState<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<_SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final notifier = ref.read(audioPlayerProvider.notifier);
    final total = state.totalDuration.inSeconds.toDouble();
    final hasDuration = total > 0;
    final position =
        _dragValue ??
        state.currentPosition.inSeconds.toDouble().clamp(
          0,
          hasDuration ? total : 0,
        );

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: const Color(0x40ffffff),
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            trackHeight: 4,
          ),
          child: Slider(
            value: hasDuration ? position.toDouble() : 0,
            max: hasDuration ? total : 1,
            onChanged:
                hasDuration ? (v) => setState(() => _dragValue = v) : null,
            onChangeEnd:
                hasDuration
                    ? (v) {
                      notifier.seekTo(Duration(seconds: v.round()));
                      setState(() => _dragValue = null);
                    }
                    : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                notifier.formatTime(Duration(seconds: position.round())),
                style: const TextStyle(color: Color(0xddffffff), fontSize: 12),
              ),
              Text(
                notifier.formatTime(state.totalDuration),
                style: const TextStyle(color: Color(0xaaffffff), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Controls extends ConsumerWidget {
  final AudioPlayerState state;

  const _Controls({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(audioPlayerProvider.notifier);
    final enabled = state.currentTrackId.isNotEmpty;
    const green = Color(0xff1BD760);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleIcon(
          icon: Icons.shuffle,
          size: 24,
          color: state.isShuffled ? green : const Color(0xB3FFFFFF),
          tooltip: 'Shuffle',
          onTap: enabled ? notifier.toggleShuffle : null,
        ),
        const SizedBox(width: 24),
        _CircleIcon(
          icon: Icons.skip_previous,
          size: 40,
          color: state.index > 0 ? Colors.white : const Color(0x4DFFFFFF),
          tooltip: 'Previous',
          onTap: state.index > 0 ? notifier.playPreviousTrack : null,
        ),
        const SizedBox(width: 20),
        _PlayButton(state: state),
        const SizedBox(width: 20),
        _CircleIcon(
          icon: Icons.skip_next,
          size: 40,
          color: enabled ? Colors.white : const Color(0x4DFFFFFF),
          tooltip: 'Next',
          onTap: enabled ? notifier.playNextTrack : null,
        ),
        const SizedBox(width: 24),
        _CircleIcon(
          icon: state.repeatMode == 2 ? Icons.repeat_one : Icons.repeat,
          size: 24,
          color: state.repeatMode > 0 ? green : const Color(0xB3FFFFFF),
          tooltip: switch (state.repeatMode) {
            1 => 'Repeat all',
            2 => 'Repeat one',
            _ => 'Repeat',
          },
          onTap: enabled ? notifier.toggleRepeat : null,
        ),
      ],
    );
  }
}

class _PlayButton extends ConsumerWidget {
  final AudioPlayerState state;

  const _PlayButton({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = state.currentTrackId.isNotEmpty;

    return Tooltip(
      message: state.isPlaying ? 'Pause (Space)' : 'Play (Space)',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap:
            enabled
                ? () => ref.read(audioPlayerProvider.notifier).togglePlayPause()
                : null,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0x33FFFFFF),
            shape: BoxShape.circle,
          ),
          child:
              state.isLoading
                  ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                  : Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 38,
                  ),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _CircleIcon({
    required this.icon,
    required this.size,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}

/// The right column on wide windows: a Lyrics / Queue toggle over the matching
/// view. Both reuse the shared widgets so behaviour stays in one place.
class _SidePanel extends StatefulWidget {
  const _SidePanel();

  @override
  State<_SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<_SidePanel> {
  int _tab = 0; // 0 = lyrics, 1 = queue

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Segmented(selected: _tab, onSelect: (i) => setState(() => _tab = i)),
          const SizedBox(height: 8),
          Expanded(
            child: _tab == 0 ? const LyricsView() : const _QueuePaneBody(),
          ),
        ],
      ),
    );
  }
}

class _QueuePaneBody extends StatelessWidget {
  const _QueuePaneBody();

  @override
  Widget build(BuildContext context) {
    // The docked panel stays open on tap, so no pop-on-tap here.
    return const QueueList();
  }
}

class _Segmented extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _Segmented({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SegmentButton(
          label: 'Lyrics',
          selected: selected == 0,
          onTap: () => onSelect(0),
        ),
        const SizedBox(width: 8),
        _SegmentButton(
          label: 'Queue',
          selected: selected == 1,
          onTap: () => onSelect(1),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color:
              selected
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0x99FFFFFF),
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Observes raw pointer events (so it never steals gestures from the sliders,
/// buttons or scrolling lyrics underneath) and dismisses when the user makes a
/// clear downward drag anywhere on the surface.
class _DragDownToDismiss extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const _DragDownToDismiss({required this.child, required this.onDismiss});

  @override
  State<_DragDownToDismiss> createState() => _DragDownToDismissState();
}

class _DragDownToDismissState extends State<_DragDownToDismiss> {
  Offset? _start;

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Watch pointers without participating in the gesture arena, so taps,
      // the seek slider and the lyrics list keep working normally.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _start = e.position,
      onPointerCancel: (_) => _start = null,
      onPointerUp: (e) {
        final start = _start;
        _start = null;
        if (start == null) return;
        final dy = e.position.dy - start.dy;
        final dx = (e.position.dx - start.dx).abs();
        // A deliberate downward pull that is clearly vertical — enough not to
        // fire on a small scroll or a stray movement during a tap.
        if (dy > 140 && dy > dx * 1.5) widget.onDismiss();
      },
      child: widget.child,
    );
  }
}
