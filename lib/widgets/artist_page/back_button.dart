import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// Floating back control for full-bleed pages on narrow windows.
///
/// The app frame already puts these pages below the status bar, so this only
/// needs to clear the page's own top padding.
class ArtistBackButton extends StatelessWidget {
  final double scrollOffset;

  const ArtistBackButton({super.key, required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: GestureDetector(
        onTap: () => context.canPop() ? context.pop() : context.go('/'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            // Scrim appears once the artwork has scrolled away and the arrow
            // would otherwise sit on plain content.
            color: scrollOffset > 200
                ? const Color(0x7F000000)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/back_arrow.svg',
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
