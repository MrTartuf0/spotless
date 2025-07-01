import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rick_spot/providers/audio_player_provider.dart';
import 'package:rick_spot/providers/searchbar_provider.dart';

class ResultTile extends ConsumerWidget {
  final String albumId;
  final String albumName;
  final String artist;
  final String artistId;
  final int duration;
  final String id;
  final String imageUri;
  final String name;
  final VoidCallback? onTap;

  const ResultTile({
    super.key,
    this.albumId = '',
    this.albumName = '',
    this.artist = 'Red Hot Chili Peppers',
    this.artistId = '',
    this.duration = 0,
    this.id = '',
    this.imageUri =
        'https://i.scdn.co/image/ab67616d0000b273de1af2785a83cc660155a0c4',
    this.name = "Can't Stop",
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
        audioNotifier.loadTrack(id);

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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(imageUri, height: 48, width: 48),
            ),
            Gap(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 17, letterSpacing: -0.2)),
                Text(
                  "Song • $artist",
                  style: TextStyle(
                    color: Color(0xaaffffff),
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
