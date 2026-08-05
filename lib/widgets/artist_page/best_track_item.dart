import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/providers/searchbar_provider.dart';
import 'package:spotACrack/utils/responsive.dart';

/// One row in an artist's popular tracks.
///
/// Hovering swaps the position number for a play glyph and lifts the row —
/// with a mouse there is no other hint that a list row is clickable.
class TrackItem extends ConsumerStatefulWidget {
  final int index;
  final String title;
  final String duration;
  final String imageUrl;
  final String trackId;

  /// Shown as a second line on wide windows, where there is room for it.
  final String albumName;
  final VoidCallback? onTap;

  const TrackItem({
    super.key,
    required this.index,
    required this.title,
    required this.duration,
    required this.trackId,
    this.imageUrl = '',
    this.albumName = '',
    this.onTap,
  });

  @override
  ConsumerState<TrackItem> createState() => _TrackItemState();
}

class _TrackItemState extends ConsumerState<TrackItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final playing = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrackId == widget.trackId),
    );
    final accent = playing ? const Color(0xff1BD760) : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          // Keep the mini player visible if we came from a search.
          ref.read(searchStateProvider.notifier).setKeyboardVisible(false);
          ref.read(audioPlayerProvider.notifier).loadTrack(widget.trackId);
          widget.onTap?.call();
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: context.pagePadding),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF1F1F1F) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: _hovered
                    ? Icon(Icons.play_arrow, size: 18, color: accent)
                    : Text(
                        '${widget.index}',
                        style: TextStyle(
                          fontSize: 14,
                          color: playing
                              ? const Color(0xff1BD760)
                              : const Color(0xB3FFFFFF),
                        ),
                      ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: widget.imageUrl.startsWith('http')
                    ? Image.network(
                        widget.imageUrl,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 15,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (context.isWide && widget.albumName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.albumName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0x99FFFFFF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                widget.duration,
                style: const TextStyle(fontSize: 13, color: Color(0x99FFFFFF)),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 42,
    height: 42,
    color: const Color(0xFF262626),
    child: const Icon(Icons.music_note, color: Colors.white38, size: 18),
  );
}

/// Row-shaped placeholder used while the discography loads.
class TrackItemSkeleton extends StatelessWidget {
  final int index;

  const TrackItemSkeleton({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.pagePadding + 8,
        vertical: 14,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$index',
              style: const TextStyle(fontSize: 14, color: Color(0x66FFFFFF)),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(height: 14, color: const Color(0x14FFFFFF)),
          ),
          const SizedBox(width: 16),
          Container(width: 32, height: 12, color: const Color(0x14FFFFFF)),
        ],
      ),
    );
  }
}
