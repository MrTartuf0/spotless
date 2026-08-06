import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/providers/lyrics_provider.dart';
import 'package:spotACrack/widgets/modal_transport.dart';
import 'package:spotACrack/widgets/playback_shortcuts.dart';

/// Full-height lyrics sheet, tinted to match the current artwork colour like
/// the rest of the player.
class LyricsSheet extends ConsumerWidget {
  const LyricsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(audioPlayerProvider.select((s) => s.dominantColor));
    final title = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrackTitle),
    );

    return PlaybackShortcuts(
      dismissible: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.isEmpty ? 'Lyrics' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Close (Esc)',
                    ),
                  ],
                ),
              ),
              const Expanded(child: LyricsView()),
              // The sheet covers the player, so skipping stays reachable
              // without closing the lyrics first.
              const ModalTransport(showClose: false),
            ],
          ),
        ),
      ),
    );
  }
}

/// The lyric lines themselves. Highlights the line matching playback position
/// and keeps it in view; tapping a line seeks to it.
class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({super.key});

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  final ScrollController _scrollController = ScrollController();

  /// Key on the active line, so it can be scrolled into view regardless of how
  /// many rows each line wrapped to.
  final GlobalKey _activeKey = GlobalKey();
  int _lastActive = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _keepActiveVisible(int active) {
    if (active == _lastActive) return;
    _lastActive = active;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _activeKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        // A third from the top reads as "now", with the next lines below it.
        alignment: 0.35,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackId = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrackId),
    );

    if (trackId.isEmpty) {
      return const _Centered('Play a track to see its lyrics');
    }

    final lyricsAsync = ref.watch(lyricsProvider(trackId));

    return lyricsAsync.when(
      loading:
          () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
      error: (_, __) => const _Centered('Could not load lyrics'),
      data: (lyrics) {
        if (!lyrics.hasLyrics || lyrics.lines.isEmpty) {
          return const _Centered('No lyrics for this track');
        }

        // Only synced lyrics track playback position; unsynced ones render as a
        // plain, un-highlighted list.
        final position =
            lyrics.synced
                ? ref.watch(
                  audioPlayerProvider.select((s) => s.currentPosition),
                )
                : Duration.zero;
        final active = lyrics.activeIndexAt(position);
        if (lyrics.synced) _keepActiveVisible(active);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
          itemCount: lyrics.lines.length,
          itemBuilder: (context, i) {
            final line = lyrics.lines[i];
            final isActive = lyrics.synced && i == active;
            final isPast = lyrics.synced && i < active;

            return Padding(
              key: isActive ? _activeKey : null,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: GestureDetector(
                // Seeking is only meaningful when the line has a real time.
                onTap:
                    lyrics.synced
                        ? () => ref
                            .read(audioPlayerProvider.notifier)
                            .seekTo(Duration(milliseconds: line.timeMs))
                        : null,
                behavior: HitTestBehavior.opaque,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color:
                        isActive
                            ? Colors.white
                            : Colors.white.withValues(
                              alpha: isPast ? 0.4 : 0.6,
                            ),
                  ),
                  textAlign: lyrics.isRtl ? TextAlign.right : TextAlign.left,
                  child: Text(
                    line.words.isEmpty ? '♪' : line.words,
                    textDirection:
                        lyrics.isRtl ? TextDirection.rtl : TextDirection.ltr,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Centered extends StatelessWidget {
  final String message;
  const _Centered(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
