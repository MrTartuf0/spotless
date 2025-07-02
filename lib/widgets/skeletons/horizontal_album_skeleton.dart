import 'package:flutter/material.dart';

class HorizontalAlbumSkeleton extends StatelessWidget {
  const HorizontalAlbumSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title skeleton
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: Color(0x5AFFFFFF),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        // Horizontal list of album skeletons
        SizedBox(
          height: 180,
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
                    // Album cover skeleton
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Color(0x5AFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),

                    SizedBox(height: 8),

                    // Album name skeleton
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Color(0x5AFFFFFF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    SizedBox(height: 4),

                    // Artist name skeleton
                    Container(
                      width: 80,
                      height: 12,
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
        ),
      ],
    );
  }
}
