import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';

import 'package:rick_spot/widgets/sheet_player.dart';
import 'package:rick_spot/providers/audio_player_provider.dart';

class BottomPlayer extends ConsumerWidget {
  const BottomPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final audioNotifier = ref.read(audioPlayerProvider.notifier);

    // Check if the image URL is valid

    if (audioState.currentTrackId.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool hasValidImage = audioState.currentTrackImage.startsWith('http');

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // allow full height
                useSafeArea: true,
                barrierColor: audioState.dominantColor, // Use extracted color
                builder: (BuildContext context) {
                  return SheetPlayer();
                },
              );
            },
            onPanUpdate: (details) {
              if (details.delta.dy < -20) {
                print("Swipe up detected");
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // allow full height
                  useSafeArea: true,
                  barrierColor: audioState.dominantColor, // Use extracted color
                  builder: (BuildContext context) {
                    return SheetPlayer();
                  },
                );
              }
            },
            child: Container(
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 70),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  height: 56,
                  decoration: BoxDecoration(
                    color: audioState.dominantColor, // Use extracted color
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child:
                              hasValidImage
                                  ? Image.network(
                                    audioState.currentTrackImage,
                                    height: 40,
                                    width: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderImage();
                                    },
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return _buildPlaceholderImage();
                                    },
                                  )
                                  : _buildPlaceholderImage(),
                        ),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                audioState.currentTrackId.isEmpty
                                    ? "Song"
                                    : audioState.currentTrackTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                  height: 1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Gap(4),
                              Text(
                                audioState.currentTrackId.isEmpty
                                    ? "Artist"
                                    : audioState.currentTrackArtist,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => audioNotifier.toggleLike(),
                          child: SvgPicture.asset(
                            'assets/icons/${audioState.isLiked ? 'fill_heart' : 'empty_heart'}.svg',
                            color:
                                audioState.isLiked
                                    ? const Color(0xff1BD760)
                                    : const Color(0x8affffff),
                          ),
                        ),
                        const Gap(24),
                        GestureDetector(
                          onTap: () => audioNotifier.togglePlayPause(),
                          child:
                              audioState.isLoading
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : SvgPicture.asset(
                                    audioState.isPlaying
                                        ? 'assets/icons/pause.svg'
                                        : 'assets/icons/play.svg',
                                    color: Colors.white,
                                  ),
                        ),
                        const Gap(8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // empty music track progress bar
          Positioned(
            bottom: 70,
            left: 16,
            right: 16,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(100),
                borderRadius: BorderRadius.circular(4),
              ),
              // filled music track progress bar
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: audioState.progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper method to build a placeholder image
Widget _buildPlaceholderImage() {
  return Container(
    height: 40,
    width: 40,
    color: Colors.grey[800],
    child: const Icon(Icons.music_note, color: Colors.white),
  );
}
