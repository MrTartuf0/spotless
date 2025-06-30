import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';

class ResultTile extends StatelessWidget {
  const ResultTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              "https://i.scdn.co/image/ab67616d0000b273de1af2785a83cc660155a0c4",
              height: 48,
              width: 48,
            ),
          ),
          Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Can't Stop",
                style: TextStyle(fontSize: 17, letterSpacing: -0.2),
              ),
              Text(
                "Song • Red Hot Chili Peppers",
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
