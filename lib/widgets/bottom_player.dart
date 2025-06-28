import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

import 'package:rick_spot/services/color_extractor.dart';
import 'package:rick_spot/widgets/sheet_player.dart';
import 'package:rick_spot/providers/audio_player_provider.dart';
import 'package:rick_spot/providers/track_provider.dart';

class BottomPlayer extends ConsumerStatefulWidget {
  const BottomPlayer({super.key});

  @override
  ConsumerState<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends ConsumerState<BottomPlayer> {
  Color containerColor = const Color(0xff424242); // Default color
  bool isLoadingColor = true;

  @override
  void initState() {
    super.initState();
    _extractColorFromCurrentTrack();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to track changes
    final audioState = ref.watch(audioPlayerProvider);
    _extractColorFromCurrentTrack();
  }

  Future<void> _extractColorFromCurrentTrack() async {
    final audioState = ref.read(audioPlayerProvider);

    try {
      final Color extractedColor = await ColorExtractor.extractDominantColor(
        NetworkImage(audioState.currentTrackImage),
      );

      if (mounted) {
        setState(() {
          containerColor = extractedColor;
          isLoadingColor = false;
        });
      }
    } catch (e) {
      print('Error extracting color: $e');
      if (mounted) {
        setState(() {
          isLoadingColor = false;
        });
      }
    }
  }

  // Call this method when track changes
  Future<void> updateTrack(String imageUrl, String title, String artist) async {
    setState(() {
      isLoadingColor = true;
    });

    try {
      final Color extractedColor = await ColorExtractor.extractDominantColor(
        NetworkImage(imageUrl),
      );

      if (mounted) {
        setState(() {
          containerColor = extractedColor;
          isLoadingColor = false;
        });
      }
    } catch (e) {
      print('Error extracting color: $e');
      if (mounted) {
        setState(() {
          isLoadingColor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioPlayerProvider);
    final audioNotifier = ref.read(audioPlayerProvider.notifier);

    // Load a specific track when needed
    // Example: ref.read(trackLoadingProvider('3d9DChrdc6BOeFsbrZ3Is0'));

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
                barrierColor: Color(0xFF7F1D1D), // red-900
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
                  barrierColor: Color(0xFF7F1D1D), // red-900
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
                    color: containerColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Image.network(
                            audioState.currentTrackImage,
                            height: 40,
                            width: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                audioState.currentTrackTitle,
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
                                audioState.currentTrackArtist,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => audioNotifier.toggleLike(),
                          child: SvgPicture.asset(
                            'assets/icons/fill_heart.svg',
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
