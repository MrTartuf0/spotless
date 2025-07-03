import 'package:flutter/material.dart';

class ArtistTileSkeleton extends StatelessWidget {
  const ArtistTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artist tile with image and name
          Row(
            children: [
              // Artist image skeleton (circular) - updated to 48x48
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0x5AFFFFFF),
                  shape: BoxShape.circle,
                ),
              ),

              SizedBox(width: 12), // Reduced spacing
              // Artist name skeleton
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 130, // Slightly reduced width
                    height: 14, // Reduced height
                    decoration: BoxDecoration(
                      color: Color(0x5AFFFFFF),
                      borderRadius: BorderRadius.circular(3), // Smaller radius
                    ),
                  ),

                  SizedBox(height: 4),

                  // Artist type skeleton
                  Container(
                    width: 50, // Slightly reduced width
                    height: 10, // Reduced height
                    decoration: BoxDecoration(
                      color: Color(0x5AFFFFFF),
                      borderRadius: BorderRadius.circular(3), // Smaller radius
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
