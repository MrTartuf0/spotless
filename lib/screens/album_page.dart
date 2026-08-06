import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/models/album.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/providers/history_provider.dart';
import 'package:spotACrack/repositories/track_repository.dart';
import 'package:spotACrack/services/color_extractor.dart';
import 'package:spotACrack/utils/responsive.dart';
import 'package:spotACrack/widgets/artist_link.dart';
import 'package:spotACrack/widgets/artist_page/back_button.dart';

/// Album page: artwork and metadata up top, then the track list.
///
/// The frame ([AppShell]) owns the Scaffold and the player, so this renders
/// only the page surface.
class AlbumPage extends ConsumerStatefulWidget {
  final String albumId;
  final String fallbackName;
  final String fallbackImage;

  const AlbumPage({
    super.key,
    required this.albumId,
    this.fallbackName = 'Album',
    this.fallbackImage = '',
  });

  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  Album? _album;
  bool _loading = true;
  String? _error;
  Color _dominantColor = const Color(0xFF2E2E2E);

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
    _extractColor(widget.fallbackImage);
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      if ((offset - _scrollOffset).abs() > 8) {
        setState(() => _scrollOffset = offset);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _extractColor(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      final color = await ColorExtractor.extractDominantColor(
        NetworkImage(imageUrl),
      );
      if (mounted) setState(() => _dominantColor = color);
    } catch (e) {
      print('Error extracting album color: $e');
    }
  }

  Future<void> _fetch() async {
    try {
      final album = await ref
          .read(trackRepositoryProvider)
          .getAlbum(widget.albumId);
      if (!mounted) return;
      setState(() {
        _album = album;
        _loading = false;
      });

      if (album.imageUrl.isNotEmpty && album.imageUrl != widget.fallbackImage) {
        _extractColor(album.imageUrl);
      }

      // Record the open after we have real data. Fire-and-forget.
      final history = ref.read(historyServiceProvider);
      history.recordAlbum(
        id: album.id.isNotEmpty ? album.id : widget.albumId,
        name: album.name,
        artist: album.artist,
        artistId: album.artistId,
        imageUrl: album.imageUrl,
      );
      // Opening an album is also how most artists end up in the library.
      if (album.artistId.isNotEmpty) {
        history.recordArtist(id: album.artistId, name: album.artist);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// The album as queue rows, artwork falling back to the album cover for
  /// tracks that carry none.
  List<Map<String, dynamic>> _queueTracks() {
    final album = _album;
    if (album == null) return const [];
    return [
      for (final t in album.tracks)
        {
          'id': t.id,
          'name': t.name,
          'artist': t.artist,
          'imageUrl': t.imageUrl.isNotEmpty ? t.imageUrl : album.imageUrl,
        },
    ];
  }

  void _playFrom(int index) {
    final tracks = _queueTracks();
    if (tracks.isEmpty) return;
    ref
        .read(audioPlayerProvider.notifier)
        .playAlbum(tracks, index, albumName: _album?.name ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final album = _album;
    final headerImage =
        album?.imageUrl.isNotEmpty == true
            ? album!.imageUrl
            : widget.fallbackImage;
    final title =
        album?.name.isNotEmpty == true ? album!.name : widget.fallbackName;

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _AlbumHeader(
                imageUrl: headerImage,
                title: title,
                artist: album?.artist ?? '',
                artistId: album?.artistId ?? '',
                trackCount: album?.tracks.length ?? 0,
                dominantColor: _dominantColor,
                onPlay:
                    (album?.tracks.isEmpty ?? true) ? null : () => _playFrom(0),
              ),
            ),

            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xff1BD760)),
                  ),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load album:\n$_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: album!.tracks.length,
                itemBuilder:
                    (context, index) => _AlbumTrackRow(
                      index: index + 1,
                      track: album.tracks[index],
                      onPlay: () => _playFrom(index),
                    ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
        if (!context.isWide) ArtistBackButton(scrollOffset: _scrollOffset),
      ],
    );
  }
}

class _AlbumHeader extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String artist;
  final String artistId;
  final int trackCount;
  final Color dominantColor;
  final VoidCallback? onPlay;

  const _AlbumHeader({
    required this.imageUrl,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.trackCount,
    required this.dominantColor,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final artSize = wide ? 208.0 : 200.0;

    final meta = Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Album',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: wide ? TextAlign.start : TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: wide ? (title.length > 24 ? 34 : 46) : 24,
            height: 1.1,
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              wide ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Flexible(
              child: ArtistLink(
                artistId: artistId,
                artistName: artist,
                style: const TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trackCount > 0)
              Text(
                '  ·  $trackCount songs',
                style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [_PlayFab(onTap: onPlay)],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [dominantColor, const Color(0xFF121212)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        context.pagePadding,
        wide ? 40 : 64,
        context.pagePadding,
        24,
      ),
      child:
          wide
              ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Artwork(imageUrl: imageUrl, size: artSize),
                  const SizedBox(width: 28),
                  Expanded(child: meta),
                ],
              )
              : Column(
                children: [
                  _Artwork(imageUrl: imageUrl, size: artSize),
                  const SizedBox(height: 20),
                  meta,
                ],
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child:
            imageUrl.startsWith('http')
                ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: context.cachePx(size),
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
                : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF2A2A2A),
    child: Icon(Icons.album, size: size * 0.35, color: Colors.white38),
  );
}

class _PlayFab extends StatefulWidget {
  final VoidCallback? onTap;

  const _PlayFab({this.onTap});

  @override
  State<_PlayFab> createState() => _PlayFabState();
}

class _PlayFabState extends State<_PlayFab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered && enabled ? 1.06 : 1,
          duration: const Duration(milliseconds: 140),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  enabled ? const Color(0xff1BD760) : const Color(0x331BD760),
            ),
            child: const Icon(Icons.play_arrow, size: 32, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class _AlbumTrackRow extends ConsumerStatefulWidget {
  final int index;
  final AlbumTrack track;
  final VoidCallback onPlay;

  const _AlbumTrackRow({
    required this.index,
    required this.track,
    required this.onPlay,
  });

  @override
  ConsumerState<_AlbumTrackRow> createState() => _AlbumTrackRowState();
}

class _AlbumTrackRowState extends ConsumerState<_AlbumTrackRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final playing = ref.watch(
      audioPlayerProvider.select((s) => s.currentTrackId == widget.track.id),
    );
    final accent = playing ? const Color(0xff1BD760) : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPlay,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: context.pagePadding),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF1F1F1F) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child:
                    _hovered
                        ? Icon(Icons.play_arrow, size: 18, color: accent)
                        : Text(
                          '${widget.index}',
                          style: TextStyle(
                            color:
                                playing
                                    ? const Color(0xff1BD760)
                                    : Colors.white54,
                            fontSize: 14,
                          ),
                        ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.track.name,
                      style: TextStyle(
                        color: accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.track.artist.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.track.artist,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.track.formattedDuration,
                style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
