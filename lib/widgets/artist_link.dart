import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Artist name that opens the artist page, wherever a track is displayed.
///
/// Falls back to plain text when the track carries no artist id — some search
/// and station payloads only have the name.
class ArtistLink extends StatelessWidget {
  final String artistId;
  final String artistName;
  final TextStyle style;
  final String fallbackLabel;

  /// Runs before navigating — used by the full-screen player to dismiss itself
  /// so the artist page isn't opened underneath it.
  final VoidCallback? onBeforeNavigate;

  const ArtistLink({
    super.key,
    required this.artistId,
    required this.artistName,
    required this.style,
    this.fallbackLabel = 'Artist',
    this.onBeforeNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final label = artistName.isEmpty ? fallbackLabel : artistName;

    if (artistId.isEmpty) {
      return Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return HoverUnderline(
      onTap: () {
        onBeforeNavigate?.call();
        context.push('/artist/$artistId?name=${Uri.encodeComponent(label)}');
      },
      builder: (hovered) => Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(
          color: hovered ? Colors.white : style.color,
          decoration: hovered ? TextDecoration.underline : null,
          decorationColor: Colors.white,
        ),
      ),
    );
  }
}

/// Underlines its child on hover — the affordance that says "this is a link"
/// on a pointer device, where there is no tap feedback to rely on.
class HoverUnderline extends StatefulWidget {
  final VoidCallback onTap;
  final Widget Function(bool hovered) builder;

  const HoverUnderline({
    super.key,
    required this.onTap,
    required this.builder,
  });

  @override
  State<HoverUnderline> createState() => _HoverUnderlineState();
}

class _HoverUnderlineState extends State<HoverUnderline> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: widget.builder(_hovered),
      ),
    );
  }
}
