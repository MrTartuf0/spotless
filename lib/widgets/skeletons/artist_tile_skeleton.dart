import 'package:flutter/material.dart';

class ArtistTileSkeleton extends StatelessWidget {
  const ArtistTileSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title skeleton
          Container(
            width: 80,
            height: 20,
            decoration: BoxDecoration(
              color: Color(0x5AFFFFFF),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          SizedBox(height: 16),

          // Artist tile with image and name
          Row(
            children: [
              // Artist image skeleton (circular)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(0x5AFFFFFF),
                  shape: BoxShape.circle,
                ),
              ),

              SizedBox(width: 16),

              // Artist name skeleton
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Color(0x5AFFFFFF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  SizedBox(height: 4),

                  // Artist type skeleton
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(0x5AFFFFFF),
                      borderRadius: BorderRadius.circular(4),
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
