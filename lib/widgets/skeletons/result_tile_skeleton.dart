import 'package:flutter/material.dart';

class ResultTileSkeleton extends StatelessWidget {
  const ResultTileSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          // Album art skeleton
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(width: 56, height: 56, color: Color(0x5AFFFFFF)),
          ),

          SizedBox(width: 16),

          // Track info skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Track name skeleton
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Color(0x5AFFFFFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                SizedBox(height: 8),

                // Artist name skeleton
                Container(
                  width: 150,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Color(0x5AFFFFFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 16),

          // Duration skeleton
          Container(
            width: 35,
            height: 14,
            decoration: BoxDecoration(
              color: Color(0x5AFFFFFF),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
