import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rick_spot/providers/audio_player/audio_player_provider.dart';
import 'package:rick_spot/providers/searchbar_provider.dart';

class TrackItem extends ConsumerWidget {
  final int index;
  final String title;
  final String duration;
  final String imageUrl;
  final String trackId;
  final VoidCallback? onTap;

  const TrackItem({
    super.key,
    required this.index,
    required this.title,
    required this.duration,
    required this.trackId,
    this.imageUrl = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        // Ensure keyboard is hidden and bottom player is visible
        ref.read(searchStateProvider.notifier).setKeyboardVisible(false);

        // Load the track
        final audioNotifier = ref.read(audioPlayerProvider.notifier);
        audioNotifier.loadTrack(trackId);

        // Show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Loading track...',
              style: TextStyle(color: Colors.black),
            ),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xff1BD760),
          ),
        );

        // Call the provided callback if any
        if (onTap != null) {
          onTap!();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
        child: Row(
          children: [
            // Song number
            SizedBox(
              width: 30,
              child: Text(
                "$index",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),

            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child:
                  imageUrl.isNotEmpty
                      ? Image.network(
                        imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[800],
                          );
                        },
                      )
                      : Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey[800],
                      ),
            ),

            SizedBox(width: 16),

            // Song title
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(width: 16),

            // Duration
            Text(
              duration,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
