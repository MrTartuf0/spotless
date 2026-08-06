import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spotACrack/models/artist_album.dart';
import 'package:spotACrack/utils/responsive.dart';

/// Releases as a grid of artwork cards.
///
/// The column count comes from the available width rather than a fixed number,
/// so the same grid works from a phone (2 up) to a wide desktop window.
class AlbumGrid extends StatelessWidget {
  final List<ArtistAlbum> albums;

  const AlbumGrid({super.key, required this.albums});

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
      sliver: SliverGrid(
        gridDelegate: _delegate(context),
        delegate: SliverChildBuilderDelegate(
          (context, index) => AlbumCard(album: albums[index]),
          childCount: albums.length,
        ),
      ),
    );
  }
}

SliverGridDelegate _delegate(BuildContext context) =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: context.isWide ? 220 : 200,
      // Room for the artwork plus two lines of text underneath.
      childAspectRatio: 0.72,
      crossAxisSpacing: 16,
      mainAxisSpacing: 20,
    );

/// Placeholder grid with the same metrics, so the layout doesn't jump when the
/// real releases arrive.
class AlbumGridSkeleton extends StatelessWidget {
  final int count;

  const AlbumGridSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
      sliver: SliverGrid(
        gridDelegate: _delegate(context),
        delegate: SliverChildBuilderDelegate(
          (context, index) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(height: 13, width: 110, color: const Color(0x14FFFFFF)),
              const SizedBox(height: 6),
              Container(height: 11, width: 70, color: const Color(0x14FFFFFF)),
            ],
          ),
          childCount: count,
        ),
      ),
    );
  }
}

class AlbumCard extends StatefulWidget {
  final ArtistAlbum album;

  const AlbumCard({super.key, required this.album});

  @override
  State<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    final subtitle = [
      if (album.releaseYear.isNotEmpty) album.releaseYear,
      if (album.totalTracks > 0)
        '${album.totalTracks} ${album.totalTracks == 1 ? 'track' : 'tracks'}',
    ].join(' • ');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap:
            album.id.isEmpty
                ? null
                : () => context.pushNamed(
                  'album',
                  pathParameters: {'albumId': album.id},
                  queryParameters: {
                    if (album.name.isNotEmpty) 'name': album.name,
                    if (album.imageUrl.isNotEmpty) 'image': album.imageUrl,
                  },
                ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // Cards only get a surface on hover, which keeps the grid quiet
            // until the pointer is actually over something.
            color: _hovered ? const Color(0xFF1F1F1F) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child:
                        album.imageUrl.startsWith('http')
                            ? Image.network(
                              album.imageUrl,
                              fit: BoxFit.cover,
                              cacheWidth: context.cachePx(220),
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                            : _placeholder(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                album.name,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF262626),
    child: const Center(
      child: Icon(Icons.album, color: Colors.white38, size: 36),
    ),
  );
}
