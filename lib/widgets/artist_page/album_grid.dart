import 'package:flutter/material.dart';

class AlbumGrid extends StatelessWidget {
  final List<Map<String, String>> albums;

  const AlbumGrid({Key? key, required this.albums}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero, // Remove default padding
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72, // Adjusted to account for text below image
          crossAxisSpacing: 16,
          mainAxisSpacing: 12, // Reduced vertical spacing from 24 to 12
        ),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          return AlbumItem(
            title: albums[index]["title"]!,
            releaseDate: albums[index]["releaseDate"]!,
            trackCount: albums[index]["trackCount"]!,
            imageUrl: albums[index]["image"]!,
          );
        },
      ),
    );
  }
}

class AlbumItem extends StatelessWidget {
  final String title;
  final String releaseDate;
  final String trackCount;
  final String imageUrl;

  const AlbumItem({
    Key? key,
    required this.title,
    required this.releaseDate,
    required this.trackCount,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate width for square image (match container width)
    final double containerWidth = (MediaQuery.of(context).size.width - 48) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Album cover - square ratio
        AspectRatio(
          aspectRatio: 1.0, // Perfect square
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: containerWidth,
              height: containerWidth, // Same as width for square aspect
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: Icon(Icons.album, color: Colors.white54, size: 40),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 8),
        // Album title
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2), // Reduced space between title and metadata
        // Album release date and track count
        Text(
          "$releaseDate • $trackCount",
          style: TextStyle(fontSize: 12, color: Colors.white70),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
