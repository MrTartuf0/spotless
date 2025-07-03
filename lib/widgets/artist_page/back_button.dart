import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ArtistBackButton extends StatelessWidget {
  final double scrollOffset;

  const ArtistBackButton({Key? key, required this.scrollOffset})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scrollOffset > 200 ? Color(0x7F000000) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/back_arrow.svg',
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
