import 'package:flutter/material.dart';

class ResultTileSkeleton extends StatelessWidget {
  const ResultTileSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          // Album art skeleton - updated to 48x48
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(width: 48, height: 48, color: Color(0x5AFFFFFF)),
          ),

          SizedBox(width: 12), // Reduced spacing to keep proportions
          // Track info skeleton - adjusted width calculation
          Container(
            width:
                MediaQuery.of(context).size.width * 0.5 -
                48 -
                28, // Half screen minus new image width and adjusted padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Track name skeleton
                Container(
                  width: double.infinity,
                  height: 14, // Smaller height to match proportions
                  decoration: BoxDecoration(
                    color: Color(0x5AFFFFFF),
                    borderRadius: BorderRadius.circular(3), // Smaller radius
                  ),
                ),

                SizedBox(height: 6), // Reduced spacing
                // Artist name skeleton
                Container(
                  width: 85, // Adjusted width proportionally
                  height: 12, // Smaller height
                  decoration: BoxDecoration(
                    color: Color(0x5AFFFFFF),
                    borderRadius: BorderRadius.circular(3), // Smaller radius
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
