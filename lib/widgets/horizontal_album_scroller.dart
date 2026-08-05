import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotACrack/providers/searchbar_provider.dart';

class HorizontalAlbumScroller extends ConsumerWidget {
  final List<Album> albums;
  final Function(Album)? onAlbumTap;

  const HorizontalAlbumScroller({
    super.key,
    required this.albums,
    this.onAlbumTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(16),
            for (int i = 0; i < albums.length; i++) ...[
              AlbumItem(
                imageUrl: albums[i].imageUri,
                albumName: albums[i].name,
                artistName: albums[i].artist,
                onTap: () {
                  ref.read(searchStateProvider.notifier).setKeyboardVisible(false);
                  if (onAlbumTap != null) {
                    onAlbumTap!(albums[i]);
                    return;
                  }
                  context.pushNamed(
                    'album',
                    pathParameters: {'albumId': albums[i].id},
                    queryParameters: {
                      if (albums[i].name.isNotEmpty) 'name': albums[i].name,
                      if (albums[i].imageUri.isNotEmpty) 'image': albums[i].imageUri,
                    },
                  );
                },
              ),
              if (i < albums.length - 1) const Gap(16),
            ],
            const Gap(16),
          ],
        ),
      ),
    );
  }
}

class AlbumItem extends StatelessWidget {
  final String imageUrl;
  final String albumName;
  final String artistName;
  final VoidCallback? onTap;

  const AlbumItem({
    super.key,
    required this.imageUrl,
    required this.albumName,
    required this.artistName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                imageUrl,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 150,
                    height: 150,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, size: 40, color: Colors.white54),
                  );
                },
              ),
            ),
            const Gap(8),
            Text(
              albumName,
              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(2),
            Text(
              artistName.isEmpty ? 'Album' : 'Album • $artistName',
              style: const TextStyle(fontSize: 12, color: Color(0xaaffffff)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class Album {
  final String artist;
  final String artistId;
  final String id;
  final String imageUri;
  final String name;

  Album({
    required this.artist,
    required this.artistId,
    required this.id,
    required this.imageUri,
    required this.name,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      artist: json['artist'] as String? ?? '',
      artistId: json['artist_id'] as String? ?? '',
      id: json['id'] as String? ?? '',
      imageUri: json['image_uri'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
