import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/widgets/artist_link.dart';
import 'package:spotACrack/widgets/up_next_sheet.dart';
import 'package:spotACrack/widgets/volume_control.dart';

class SheetPlayer extends ConsumerWidget {
  const SheetPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final audioNotifier = ref.read(audioPlayerProvider.notifier);

    return AnimatedContainer(
      // Playback no longer waits for colour extraction, so the gradient fades
      // to the new artwork colour instead of snapping to it.
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            audioState.dominantColor, // Use extracted color
            Colors.black, // Fade to black
          ],
        ),
      ),
      child: Column(
        children: [
          const SheetGrabber(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: SvgPicture.asset(
                    'assets/icons/chevron_down.svg',
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Text(
                    audioState.currentTrackId.isEmpty
                        ? 'Album'
                        : audioState.currentAlbumName,
                    style: const TextStyle(
                      color: Colors.white,
                      letterSpacing: -0.2,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/more_options.svg',
                  color: Colors.white,
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Image.network(
                audioState.currentTrackId.isEmpty
                    ? 'https://placehold.co/420x420.png'
                    : audioState.currentTrackImage,
              ),
            ),
          ),

          // Song Info
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audioState.currentTrackId.isEmpty
                            ? "Song Title"
                            : audioState.currentTrackTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      ArtistLink(
                        artistId: audioState.currentArtistId,
                        artistName: audioState.currentTrackArtist,
                        // The sheet sits above the router's navigator, so it
                        // has to close before the artist page is pushed.
                        onBeforeNavigate: () => Navigator.pop(context),
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => audioNotifier.toggleLike(),
                  child: SvgPicture.asset(
                    'assets/icons/${audioState.isLiked ? 'fill_heart.svg' : 'empty_heart.svg'}',
                    color:
                        audioState.isLiked
                            ? Color(0xff1BD760)
                            : Color(0x8affffff),
                  ),
                ),
              ],
            ),
          ),

          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Color(0x64ffffff),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: audioState.currentPosition.inSeconds.toDouble(),
                    max: audioState.totalDuration.inSeconds.toDouble(),
                    onChanged: (value) {
                      audioNotifier.seekTo(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        audioNotifier.formatTime(audioState.currentPosition),
                        style: TextStyle(
                          color: Color(0xddffffff),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        audioNotifier.formatTime(audioState.totalDuration),
                        style: TextStyle(
                          color: Color(0xaaffffff),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => audioNotifier.toggleShuffle(),
                  child: SvgPicture.asset(
                    'assets/icons/shuffle.svg',
                    color:
                        audioState.isShuffled
                            ? Color(0xff1BD760)
                            : Color(0x8affffff),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (audioState.index > 0) {
                      audioNotifier.playPreviousTrack();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No previous track available',
                            style: TextStyle(color: Colors.black),
                          ),
                          backgroundColor: Color(0xff1BD760),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: SvgPicture.asset(
                    'assets/icons/previous.svg',
                    color:
                        audioState.index > 0
                            ? Colors.white
                            : const Color(0x4Dffffff), // dimmed if disabled
                    height: 32,
                  ),
                ),

                GestureDetector(
                  onTap: () => audioNotifier.togglePlayPause(),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child:
                        audioState.isLoading
                            ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                            : Icon(
                              audioState.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.black,
                              size: 32,
                            ),
                  ),
                ),

                // Next track button with correct action
                // In the SheetPlayer, let's add a small indicator for when next track is prefetching
                // At the Next Track button section:
                GestureDetector(
                  onTap: () {
                    // Indexing trackIdHistory unguarded threw a RangeError
                    // before anything had played (index is -1 until then).
                    final hasQueued =
                        audioState.index >= 0 &&
                        audioState.index < audioState.trackIdHistory.length &&
                        audioState.trackIdHistory[audioState.index].isNotEmpty;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          hasQueued
                              ? 'Playing next track: ${audioState.currentTrackTitle}'
                              : 'Finding next track...',
                          style: TextStyle(color: Colors.black),
                        ),
                        backgroundColor: Color(0xff1BD760),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    // Call the playNextTrack method
                    audioNotifier.playNextTrack();
                  },
                  child: Stack(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/forward.svg',
                        color: Colors.white,
                        height: 32,
                      ),
                      if (audioState.isLoading)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(0xff1BD760),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                      if (audioState.index >= 0 &&
                          audioState.index < audioState.trackIdHistory.length &&
                          audioState
                              .trackIdHistory[audioState.index]
                              .isNotEmpty &&
                          !audioState.isLoading)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                GestureDetector(
                  onTap: () => audioNotifier.toggleRepeat(),
                  child: Stack(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/repeat.svg',
                        color:
                            audioState.repeatMode > 0
                                ? Color(0xff1BD760)
                                : Color(0x8affffff),
                      ),
                      if (audioState.repeatMode == 2)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(4),

          // Volume lives here on phones, where there is no persistent bar to
          // put it in.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: VolumeControl(sliderWidth: 160),
          ),

          // Up next: opens the station queued behind this track.
          SafeArea(
            top: false,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.black.withValues(alpha: 0.5),
                  builder: (_) => const UpNextSheet(),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.queue_music,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const Gap(8),
                    Text(
                      'Up next',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
