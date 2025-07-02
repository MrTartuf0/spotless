import 'package:flutter/material.dart';

class HorizontalAlbumSkeleton extends StatelessWidget {
  const HorizontalAlbumSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return
    // Horizontal list of album skeletons
    SizedBox(
      height: 220, // Increased height to accommodate larger images
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Album cover skeleton - updated to 150x150
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Color(0x5AFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                SizedBox(height: 10), // Slightly increased spacing
                // Album name skeleton - adjusted width proportionally
                Container(
                  width:
                      125, // Increased proportionally (was 100 for 120px image)
                  height:
                      16, // Slightly larger for better proportion with bigger image
                  decoration: BoxDecoration(
                    color: Color(0x5AFFFFFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                SizedBox(height: 5), // Slightly increased spacing
                // Artist name skeleton - adjusted width proportionally
                Container(
                  width:
                      100, // Increased proportionally (was 80 for 120px image)
                  height: 14, // Slightly larger
                  decoration: BoxDecoration(
                    color: Color(0x5AFFFFFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
