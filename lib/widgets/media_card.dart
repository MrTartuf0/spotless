import 'package:flutter/material.dart';
import 'package:spotACrack/utils/responsive.dart';

/// Square artwork card used by the horizontal rows on Home and Library.
///
/// Sized to show roughly two and a half cards on a phone, which is the hint
/// that the row keeps going; wider windows get larger cards.
class MediaCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final double size;
  final bool circular;

  const MediaCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.size = 148,
    this.circular = false,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.size,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The artwork lifts under the pointer; on touch nothing changes.
              AnimatedScale(
                scale: _hovered ? 1.03 : 1,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    widget.circular ? widget.size : 8,
                  ),
                  child: _Artwork(
                    imageUrl: widget.imageUrl,
                    size: widget.size,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: widget.circular ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (widget.subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign:
                      widget.circular ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _Artwork({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    if (!imageUrl.startsWith('http')) return _placeholder();

    return Image.network(
      imageUrl,
      height: size,
      width: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
      // Fade in rather than popping once the bytes land.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: frame == null ? _placeholder() : child,
        );
      },
    );
  }

  Widget _placeholder() => Container(
    height: size,
    width: size,
    color: const Color(0xFF262626),
    child: Icon(
      Icons.music_note,
      color: Colors.white.withValues(alpha: 0.35),
      size: size * 0.3,
    ),
  );
}

/// Section title with the row of cards underneath it.
class MediaRow extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const MediaRow({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final padding = context.pagePadding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 24, padding, 12),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: context.isWide ? 22 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: padding),
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const SizedBox(width: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
