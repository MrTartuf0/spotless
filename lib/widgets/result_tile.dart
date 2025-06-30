import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';

class ResultTile extends StatelessWidget {
  final String albumId;
  final String albumName;
  final String artist;
  final String artistId;
  final int duration;
  final String id;
  final String imageUri;
  final String name;

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
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}
