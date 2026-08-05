import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/providers/audio_player/audio_player_state.dart';
import 'package:spotACrack/providers/ui_provider.dart';
import 'package:spotACrack/utils/responsive.dart';
import 'package:spotACrack/widgets/artist_link.dart';
import 'package:spotACrack/widgets/sheet_player.dart';
import 'package:spotACrack/widgets/up_next_sheet.dart';
import 'package:spotACrack/widgets/volume_control.dart';

/// Full-width transport bar along the bottom of the desktop layout.
///
/// Unlike the phone mini player this stays put even with nothing loaded, so
/// the content area doesn't resize the first time a track starts.
class DesktopPlayerBar extends ConsumerWidget {
  const DesktopPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioPlayerProvider);

    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF1F1F1F), width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 3, child: _NowPlaying(state: state)),
          Expanded(
            flex: 5,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: _Transport(state: state),
              ),
            ),
          ),
          Expanded(flex: 3, child: _Extras(state: state)),
        ],
      ),
    );
  }
}

class _NowPlaying extends ConsumerWidget {
  final AudioPlayerState state;

  const _NowPlaying({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.currentTrackId.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Nothing playing',
          style: TextStyle(color: Color(0x66FFFFFF), fontSize: 13),
        ),
      );
    }

    final hasImage = state.currentTrackImage.startsWith('http');

    return Row(
      children: [
        // The artwork is the way back into the full player on desktop, the
        // same role the whole mini player plays on a phone.
        Tooltip(
          message: 'Open player',
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              barrierColor: state.dominantColor.withValues(alpha: 0.5),
              constraints: const BoxConstraints(maxWidth: 560),
              builder: (_) => const SheetPlayer(),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: hasImage
                  ? Image.network(
                      state.currentTrackImage,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _artPlaceholder(),
                    )
                  : _artPlaceholder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.currentTrackTitle.isEmpty
                    ? 'Song'
                    : state.currentTrackTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              ArtistLink(
                artistId: state.currentArtistId,
                artistName: state.currentTrackArtist,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _IconAction(
          asset: state.isLiked ? 'fill_heart' : 'empty_heart',
          tooltip: state.isLiked ? 'Remove from liked' : 'Add to liked',
          color: state.isLiked ? const Color(0xff1BD760) : const Color(0x8affffff),
          onTap: () => ref.read(audioPlayerProvider.notifier).toggleLike(),
          size: 18,
        ),
      ],
    );
  }

  Widget _artPlaceholder() => Container(
    width: 56,
    height: 56,
    color: const Color(0xFF262626),
    child: const Icon(Icons.music_note, color: Colors.white38, size: 22),
  );
}

class _Transport extends ConsumerWidget {
  final AudioPlayerState state;

  const _Transport({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(audioPlayerProvider.notifier);
    final enabled = state.currentTrackId.isNotEmpty;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _IconAction(
              asset: 'shuffle',
              tooltip: 'Shuffle',
              color: state.isShuffled
                  ? const Color(0xff1BD760)
                  : const Color(0x8affffff),
              onTap: enabled ? notifier.toggleShuffle : null,
            ),
            const SizedBox(width: 18),
            _IconAction(
              asset: 'previous',
              tooltip: 'Previous (Ctrl+←)',
              size: 20,
              color: state.index > 0 ? Colors.white : const Color(0x4Dffffff),
              onTap: state.index > 0 ? notifier.playPreviousTrack : null,
            ),
            const SizedBox(width: 18),
            _PlayButton(state: state),
            const SizedBox(width: 18),
            _IconAction(
              asset: 'forward',
              tooltip: 'Next (Ctrl+→)',
              size: 20,
              color: enabled ? Colors.white : const Color(0x4Dffffff),
              onTap: enabled ? notifier.playNextTrack : null,
            ),
            const SizedBox(width: 18),
            _IconAction(
              asset: 'repeat',
              tooltip: switch (state.repeatMode) {
                1 => 'Repeat all',
                2 => 'Repeat one',
                _ => 'Repeat',
              },
              color: state.repeatMode > 0
                  ? const Color(0xff1BD760)
                  : const Color(0x8affffff),
              onTap: enabled ? notifier.toggleRepeat : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _SeekBar(state: state),
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
        onTap: enabled
            ? () => ref.read(audioPlayerProvider.notifier).togglePlayPause()
            : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0x33FFFFFF),
            shape: BoxShape.circle,
          ),
          child: state.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Icon(
                  state.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                  size: 22,
                ),
        ),
      ),
    );
  }
}

/// Seek slider with elapsed/remaining times.
///
/// While dragging it shows the dragged position instead of the playback
/// position, otherwise the thumb fights the position stream and jumps back.
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
    final position = _dragValue ??
        state.currentPosition.inSeconds.toDouble().clamp(0, hasDuration ? total : 0);

    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            notifier.formatTime(
              Duration(seconds: position.round()),
            ),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(0xaaffffff), fontSize: 11),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: const Color(0x40ffffff),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              trackHeight: 3,
            ),
            child: Slider(
              value: hasDuration ? position.toDouble() : 0,
              max: hasDuration ? total : 1,
              onChanged: hasDuration
                  ? (value) => setState(() => _dragValue = value)
                  : null,
              onChangeEnd: hasDuration
                  ? (value) {
                      notifier.seekTo(Duration(seconds: value.round()));
                      setState(() => _dragValue = null);
                    }
                  : null,
            ),
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            notifier.formatTime(state.totalDuration),
            style: const TextStyle(color: Color(0xaaffffff), fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _Extras extends ConsumerWidget {
  final AudioPlayerState state;

  const _Extras({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueOpen = ref.watch(queuePanelOpenProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: queueOpen ? 'Hide queue' : 'Show queue',
          onPressed: () {
            // Narrow windows have no room to dock the panel, so they get the
            // same sheet the phone layout uses.
            if (context.isExpanded) {
              ref.read(queuePanelOpenProvider.notifier).state = !queueOpen;
            } else {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                constraints: const BoxConstraints(maxWidth: 560),
                builder: (_) => const UpNextSheet(),
              );
            }
          },
          icon: Icon(
            Icons.queue_music,
            size: 20,
            color: queueOpen ? const Color(0xff1BD760) : const Color(0xB3FFFFFF),
          ),
        ),
        // The slider needs room; below that width the mute button alone still
        // gives you a way to silence playback.
        VolumeControl(sliderWidth: context.isExpanded ? 110 : 0),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  final String asset;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;
  final double size;

  const _IconAction({
    required this.asset,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.size = 16,
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
          child: SvgPicture.asset(
            'assets/icons/$asset.svg',
            height: size,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
