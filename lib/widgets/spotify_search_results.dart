import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/providers/search_result_provider.dart';
import 'package:spotACrack/providers/searchbar_provider.dart';
import 'package:spotACrack/utils/responsive.dart';
import 'package:spotACrack/widgets/artist_avatar_card.dart';
import 'package:spotACrack/widgets/horizontal_album_scroller.dart';
import 'package:spotACrack/widgets/result_tile.dart';

/// Spotify-style search results: Top Result card → Songs → Artists → Albums.
///
/// On wide windows the top result and the song list sit side by side, the way
/// they do in the desktop client; narrow windows stack them.
///
/// Artists come from deduping `artistId` across the returned tracks (the
/// backend search endpoint doesn't include an explicit artists array).
class SpotifySearchResults extends ConsumerWidget {
  const SpotifySearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);

    final tracks = results.tracks;
    final albums = results.albums;

    // Dedupe artists by id, preserve order of first appearance, cap at 8.
    final seenArtists = <String>{};
    final artistRefs = <_ArtistRef>[];
    for (final t in tracks) {
      final id = (t['artistId'] as String?) ?? '';
      if (id.isEmpty || seenArtists.contains(id)) continue;
      seenArtists.add(id);
      artistRefs.add(_ArtistRef(id: id, name: (t['artist'] as String?) ?? ''));
      if (artistRefs.length >= 8) break;
    }

    final topTrack = tracks.isNotEmpty ? tracks.first : null;
    final wide = context.isWide;

    final songList = [
      for (final track in tracks.take(wide ? 6 : 4))
        ResultTile(
          albumId: (track['albumId'] as String?) ?? '',
          albumName: (track['albumName'] as String?) ?? '',
          artist: (track['artist'] as String?) ?? '',
          artistId: (track['artistId'] as String?) ?? '',
          duration: (track['duration'] as int?) ?? 0,
          id: (track['id'] as String?) ?? '',
          imageUri: (track['imageUri'] as String?) ?? '',
          name: (track['name'] as String?) ?? '',
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (wide && topTrack != null)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(title: 'Top result'),
                        _TopResultCard(track: topTrack),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(title: 'Songs'),
                        ...songList,
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (topTrack != null) ...[
              const _SectionHeader(title: 'Top result'),
              _TopResultCard(track: topTrack),
            ],
            if (tracks.isNotEmpty) ...[
              const _SectionHeader(title: 'Songs'),
              ...songList,
            ],
          ],
          if (artistRefs.isNotEmpty) ...[
            const _SectionHeader(title: 'Artists'),
            _ArtistScroller(artists: artistRefs),
          ],
          if (albums.isNotEmpty) ...[
            const _SectionHeader(title: 'Albums'),
            HorizontalAlbumScroller(albums: albums),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.pagePadding, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: context.isWide ? 20 : 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TopResultCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> track;
  const _TopResultCard({required this.track});

  @override
  ConsumerState<_TopResultCard> createState() => _TopResultCardState();
}

class _TopResultCardState extends ConsumerState<_TopResultCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final trackId = (track['id'] as String?) ?? '';
    final title = (track['name'] as String?) ?? '';
    final artist = (track['artist'] as String?) ?? '';
    final image = (track['imageUri'] as String?) ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.pagePadding,
        vertical: 4,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () {
            ref.read(searchStateProvider.notifier).setKeyboardVisible(false);
            ref.read(audioPlayerProvider.notifier).loadTrack(trackId);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color:
                  _hovered ? const Color(0xFF2A2A2A) : const Color(0xff1e1e1e),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child:
                      image.isNotEmpty
                          ? Image.network(
                            image,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            cacheWidth: context.cachePx(96),
                            errorBuilder:
                                (_, __, ___) => _topResultPlaceholder(),
                          )
                          : _topResultPlaceholder(),
                ),
                const Gap(12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Song',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        artist,
                        style: const TextStyle(
                          color: Color(0xaaffffff),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topResultPlaceholder() {
    return Container(
      width: 96,
      height: 96,
      color: Colors.grey[800],
      child: const Icon(Icons.music_note, color: Colors.white54, size: 40),
    );
  }
}

class _ArtistRef {
  final String id;
  final String name;
  const _ArtistRef({required this.id, required this.name});
}

/// Search hits carry no artist artwork, so the cards resolve it themselves —
/// the same path Home and the library use.
class _ArtistScroller extends StatelessWidget {
  final List<_ArtistRef> artists;
  const _ArtistScroller({required this.artists});

  @override
  Widget build(BuildContext context) {
    final padding = context.pagePadding;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: padding),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (int i = 0; i < artists.length; i++) ...[
              ArtistAvatarCard(
                artistId: artists[i].id,
                name: artists[i].name,
                size: context.isWide ? 140 : 128,
              ),
              if (i < artists.length - 1) const Gap(16),
            ],
          ],
        ),
      ),
    );
  }
}
