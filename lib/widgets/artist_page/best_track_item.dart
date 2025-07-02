import 'package:flutter/material.dart';

class TrackItem extends StatelessWidget {
  final int index;
  final String title;
  final String duration;
  final String imageUrl;

  const TrackItem({
    Key? key,
    required this.index,
    required this.title,
    required this.duration,
    this.imageUrl = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    : Container(width: 40, height: 40, color: Colors.grey[800]),
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
          Text(duration, style: TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }
}
