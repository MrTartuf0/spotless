import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/providers/history_provider.dart';
import 'package:spotACrack/providers/recommendations_provider.dart';
import 'package:spotACrack/screens/app_shell.dart';
import 'package:spotACrack/services/history_service.dart';
import 'package:spotACrack/utils/responsive.dart';
import 'package:spotACrack/widgets/artist_avatar_card.dart';
import 'package:spotACrack/widgets/media_card.dart';

/// Home tab: what you were last listening to, and where the station would take
/// you from there.
class HomeFeed extends ConsumerWidget {
  const HomeFeed({super.key});

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTracks = ref.watch(recentTracksProvider);
    final recentAlbums = ref.watch(recentAlbumsProvider);
    final recentArtists = ref.watch(recentArtistsProvider);
    final audioState = ref.watch(audioPlayerProvider);
    final cardSize = context.mediaCardSize;

    // Seed the station from whatever is playing, falling back to the last
    // thing played so the row survives a cold start.
    final tracks = recentTracks.valueOrNull ?? const <RecentTrack>[];
    final seedId =
        audioState.currentTrackId.isNotEmpty
            ? audioState.currentTrackId
            : (tracks.isNotEmpty ? tracks.first.id : '');
    final seedName =
        audioState.currentTrackId.isNotEmpty
            ? audioState.currentTrackTitle
            : (tracks.isNotEmpty ? tracks.first.title : '');

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
          // The frame supplies its own back affordance, and the tabs have
          // nothing to go back to.
          automaticallyImplyLeading: false,
          title: Text(
            _greeting(),
            style: TextStyle(
              color: Colors.white,
              fontSize: context.isWide ? 28 : 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: context.pagePadding - 8),
              child: IconButton(
                onPressed: () => AppShell.selectTab(context, ref, 1),
                icon: const Icon(Icons.search, color: Colors.white),
                iconSize: 26,
                tooltip: 'Search',
              ),
            ),
          ],
        ),

        if (tracks.isEmpty && recentTracks.isLoading)
          const SliverToBoxAdapter(child: _RowSkeleton()),

        if (tracks.isEmpty && !recentTracks.isLoading)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyHome()),

        if (tracks.isNotEmpty)
          SliverToBoxAdapter(
            child: MediaRow(
              title: 'Jump back in',
              children: [
                for (final track in tracks.take(12))
                  MediaCard(
                    imageUrl: track.imageUrl,
                    title: track.title,
                    subtitle: track.artist,
                    size: cardSize,
                    onTap:
                        () => ref
                            .read(audioPlayerProvider.notifier)
                            .loadTrack(track.id),
                  ),
              ],
            ),
          ),

        // Artists come from everything played and every album opened, so this
        // shelf fills itself without a follow list.
        SliverToBoxAdapter(
          child: MediaRow(
            title: 'Your artists',
            children: [
              for (final artist in (recentArtists.valueOrNull ??
                      const <RecentArtist>[])
                  .take(10))
                ArtistAvatarCard(
                  artistId: artist.id,
                  name: artist.name,
                  imageUrl: artist.imageUrl,
                  size: cardSize,
                ),
            ],
          ),
        ),

        if (seedId.isNotEmpty)
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, _) {
                final station = ref.watch(recommendedTracksProvider(seedId));

                return station.when(
                  loading: () => const _RowSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (items) {
                    if (items.isEmpty) return const SizedBox.shrink();
                    return MediaRow(
                      title:
                          seedName.isEmpty
                              ? 'More like this'
                              : 'More like $seedName',
                      children: [
                        for (final track in items)
                          MediaCard(
                            imageUrl: track['imageUrl'] as String? ?? '',
                            title: track['name'] as String? ?? '',
                            subtitle: track['artist'] as String? ?? '',
                            size: cardSize,
                            onTap:
                                () => ref
                                    .read(audioPlayerProvider.notifier)
                                    .loadTrack(track['id'] as String),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

        SliverToBoxAdapter(
          child: MediaRow(
            title: 'Albums you opened',
            children: [
              for (final album in (recentAlbums.valueOrNull ??
                      const <RecentAlbum>[])
                  .take(12))
                MediaCard(
                  imageUrl: album.imageUrl,
                  title: album.name,
                  subtitle: album.artist,
                  size: cardSize,
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
                ),
            ],
          ),
        ),

        // Clearance for the mini player and nav bar.
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.graphic_eq,
            size: 48,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nothing here yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Play something and it will show up here, along with a station built from it.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder row that keeps the layout from jumping while data loads.
class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    final padding = context.pagePadding;
    final size = context.mediaCardSize;

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 24, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 18,
            width: 160,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          // Clipped rather than wrapped: three cards are wider than a phone,
          // and the real row they stand in for scrolls off-screen too.
          SizedBox(
            height: size,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: size * 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      Container(
                        height: size,
                        width: size,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
