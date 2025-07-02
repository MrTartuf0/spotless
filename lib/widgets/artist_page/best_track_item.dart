import 'package:flutter/material.dart';

class TrackItem extends StatelessWidget {
  final int index;
  final String title;
  final String duration;

  const TrackItem({
    Key? key,
    required this.index,
    required this.title,
    required this.duration,
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

          // Album art placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(width: 40, height: 40, color: Colors.grey[800]),
          ),

          SizedBox(width: 16),

          // Song title
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16, color: Colors.white),
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
