import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class HorizontalAlbumScroller extends StatelessWidget {
  final List<Album> albums;

  const HorizontalAlbumScroller({super.key, required this.albums});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 28, 0, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              [
                const Gap(12), // Starting gap
                ...albums.map(
                  (album) => AlbumItem(
                    imageUrl: album.imageUri,
                    albumName: album.name,
                    artistName: album.artist,
                  ),
                ),
              ].expand((widget) {
                if (widget is AlbumItem) {
                  return [
                    widget,
                    if (albums.indexOf(
                          albums.firstWhere(
                            (a) => a.imageUri == widget.imageUrl,
                          ),
                        ) <
                        albums.length - 1)
                      const Gap(16), // Gap between albums
                  ];
                }
                return [widget];
              }).toList(),
        ),
      ),
    );
  }
}

class AlbumItem extends StatelessWidget {
  final String imageUrl;
  final String albumName;
  final String artistName;

  const AlbumItem({
    super.key,
    required this.imageUrl,
    required this.albumName,
    required this.artistName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
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
                color: Colors.grey[300],
                child: const Icon(
                  Icons.music_note,
                  size: 40,
                  color: Colors.grey,
                ),
              );
            },
          ),
        ),
        const Gap(8), // Gap between image and text
        SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                albumName,
                style: const TextStyle(
                  fontSize: 16,
                  letterSpacing: 0,
                  height: 0,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
      artist: json['artist'],
      artistId: json['artist_id'],
      id: json['id'],
      imageUri: json['image_uri'],
      name: json['name'],
    );
  }
}
