import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotACrack/providers/artist_provider.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/providers/history_provider.dart';
import 'package:spotACrack/services/history_service.dart';
import 'package:spotACrack/utils/responsive.dart';

enum _LibraryFilter { songs, albums, artists }

/// Library tab: everything played or opened, most recent first.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  _LibraryFilter _filter = _LibraryFilter.songs;

  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(recentTracksProvider).valueOrNull ?? const [];
    final albums = ref.watch(recentAlbumsProvider).valueOrNull ?? const [];
    final artists = ref.watch(recentArtistsProvider).valueOrNull ?? const [];

    final isEmpty = switch (_filter) {
      _LibraryFilter.songs => tracks.isEmpty,
      _LibraryFilter.albums => albums.isEmpty,
      _LibraryFilter.artists => artists.isEmpty,
    };

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xFF121212),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: context.pagePadding,
          automaticallyImplyLeading: false,
          title: Text(
            'Your library',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.isWide ? 28 : 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.pagePadding, 0, 16, 12),
                child: Row(
                  children: [
                    for (final filter in _LibraryFilter.values) ...[
                      _FilterChip(
                        label: switch (filter) {
                          _LibraryFilter.songs => 'Songs',
                          _LibraryFilter.albums => 'Albums',
                          _LibraryFilter.artists => 'Artists',
                        },
                        selected: _filter == filter,
                        onTap: () => setState(() => _filter = filter),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        if (isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                switch (_filter) {
                  _LibraryFilter.songs => 'No songs played yet',
                  _LibraryFilter.albums => 'No albums opened yet',
                  _LibraryFilter.artists => 'No artists yet',
                },
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 15,
                ),
              ),
            ),
          )
        else
          switch (_filter) {
            _LibraryFilter.albums => SliverList.builder(
              itemCount: albums.length,
              itemBuilder: (context, i) {
                final RecentAlbum album = albums[i];
                return _LibraryTile(
                  imageUrl: album.imageUrl,
                  title: album.name,
                  subtitle: 'Album · ${album.artist}',
                  onTap:
                      () => context.pushNamed(
                        'album',
                        pathParameters: {'albumId': album.id},
                        queryParameters: {
                          if (album.name.isNotEmpty) 'name': album.name,
                          if (album.imageUrl.isNotEmpty)
                            'image': album.imageUrl,
                        },
                      ),
                );
              },
            ),
            _LibraryFilter.artists => SliverList.builder(
              itemCount: artists.length,
              itemBuilder: (context, i) => _ArtistTile(artist: artists[i]),
            ),
            _LibraryFilter.songs => SliverList.builder(
              itemCount: tracks.length,
              itemBuilder: (context, i) {
                final RecentTrack track = tracks[i];
                return _LibraryTile(
                  imageUrl: track.imageUrl,
                  title: track.title,
                  subtitle: 'Song · ${track.artist}',
                  onTap:
                      () => ref
                          .read(audioPlayerProvider.notifier)
                          .loadTrack(track.id),
                );
              },
            ),
          },

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/// Artist row. Artwork is resolved on demand for artists that were picked up
/// from playback, which only carries an id and a name.
class _ArtistTile extends ConsumerWidget {
  final RecentArtist artist;

  const _ArtistTile({required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var image = artist.imageUrl;

    if (image.isEmpty && artist.id.isNotEmpty) {
      final profile = ref.watch(artistProfileProvider(artist.id)).valueOrNull;
      final resolved =
          profile?.thumbnailUrl.isNotEmpty == true
              ? profile!.thumbnailUrl
              : (profile?.imageUrl ?? '');
      if (resolved.isNotEmpty) {
        image = resolved;
        ref.read(historyServiceProvider).updateArtistImage(artist.id, resolved);
      }
    }

    return _LibraryTile(
      imageUrl: image,
      title: artist.name,
      subtitle: 'Artist',
      circular: true,
      onTap:
          () => context.push(
            '/artist/${artist.id}'
            '?name=${Uri.encodeComponent(artist.name)}'
            '&image=${Uri.encodeComponent(image)}',
          ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color:
                selected
                    ? const Color(0xff1BD760)
                    : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryTile extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool circular;

  const _LibraryTile({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.circular = false,
  });

  @override
  State<_LibraryTile> createState() => _LibraryTileState();
}

class _LibraryTileState extends State<_LibraryTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.circular ? 26 : 4);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: context.pagePadding - 8,
            vertical: 2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF1F1F1F) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: radius,
                child:
                    widget.imageUrl.startsWith('http')
                        ? Image.network(
                          widget.imageUrl,
                          height: 52,
                          width: 52,
                          fit: BoxFit.cover,
                          cacheWidth: context.cachePx(52),
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                        : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 52,
    width: 52,
    color: const Color(0xFF262626),
    child: Icon(
      widget.circular ? Icons.person : Icons.music_note,
      color: Colors.white38,
      size: 22,
    ),
  );
}
