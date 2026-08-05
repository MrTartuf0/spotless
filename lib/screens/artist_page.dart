import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/models/artist_profile.dart';
import 'package:spotACrack/providers/artist_provider.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/providers/history_provider.dart';
import 'package:spotACrack/services/artist_service.dart';
import 'package:spotACrack/services/color_extractor.dart';
import 'package:spotACrack/utils/responsive.dart';
import 'package:spotACrack/widgets/artist_page/album_grid.dart';
import 'package:spotACrack/widgets/artist_page/artist_header.dart';
import 'package:spotACrack/widgets/artist_page/back_button.dart';
import 'package:spotACrack/widgets/artist_page/best_track_item.dart';

/// Artist page: header, popular tracks, then everything they released.
///
/// Runs off two independent requests — the profile (name, artwork, followers)
/// and the discography — so the header can render as soon as either one lands
/// instead of waiting for both.
class ArtistPage extends ConsumerStatefulWidget {
  final String artistId;
  final String artistName;
  final String artistImage;

  const ArtistPage({
    super.key,
    required this.artistId,
    required this.artistName,
    this.artistImage = '',
  });

  @override
  ConsumerState<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends ConsumerState<ArtistPage> {
  Color _dominantColor = const Color(0xff491d18);
  bool _showAllTracks = false;

  /// Artwork the current colour was pulled from, so a rebuild doesn't kick off
  /// the same extraction again.
  String _colorSource = '';

  /// Artist we have already written to history, for the same reason.
  String _recorded = '';

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _extractColor(widget.artistImage);
    _scrollController.addListener(() {
      // Only the back button reads this, and only to decide whether it needs a
      // scrim, so cheap threshold updates are enough.
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
    if (imageUrl.isEmpty || imageUrl == _colorSource) return;
    _colorSource = imageUrl;

    try {
      final color = await ColorExtractor.extractDominantColor(
        NetworkImage(imageUrl),
      );
      if (mounted) setState(() => _dominantColor = color);
    } catch (e) {
      print('Error extracting artist color: $e');
    }
  }

  void _record(ArtistProfile profile) {
    if (widget.artistId.isEmpty || _recorded == widget.artistId) return;
    _recorded = widget.artistId;

    ref.read(historyServiceProvider).recordArtist(
          id: widget.artistId,
          name: profile.name.isNotEmpty ? profile.name : widget.artistName,
          imageUrl: profile.imageUrl.isNotEmpty
              ? profile.imageUrl
              : widget.artistImage,
        );
  }

  void _play(Discography discography) {
    if (discography.tracks.isEmpty) return;
    ref
        .read(audioPlayerProvider.notifier)
        .loadTrack(discography.tracks.first.id);
  }

  void _shuffle(Discography discography) {
    if (discography.tracks.isEmpty) return;
    final pick = discography.tracks[Random().nextInt(discography.tracks.length)];
    ref.read(audioPlayerProvider.notifier).loadTrack(pick.id);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(artistProfileProvider(widget.artistId));
    final discographyAsync =
        ref.watch(artistDiscographyProvider(widget.artistId));

    final profile = profileAsync.valueOrNull;
    if (profile != null) {
      _record(profile);
      // Prefer the artist's own artwork over whatever the caller passed.
      if (profile.imageUrl.isNotEmpty) _extractColor(profile.imageUrl);
    }

    final discography = discographyAsync.valueOrNull ?? const Discography();
    final loadingTracks = discographyAsync.isLoading;
    final failed = discographyAsync.hasError;

    final tracks = discography.tracks;
    final shown = _showAllTracks ? tracks : tracks.take(5).toList();

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: ArtistHeader(
                artistName: widget.artistName,
                artistImage: widget.artistImage,
                profile: profile,
                dominantColor: _dominantColor,
                onPlay: tracks.isEmpty ? null : () => _play(discography),
                onShuffle: tracks.isEmpty ? null : () => _shuffle(discography),
              ),
            ),

            if (failed)
              SliverToBoxAdapter(
                child: _LoadFailed(
                  onRetry: () => ref.invalidate(
                    artistDiscographyProvider(widget.artistId),
                  ),
                ),
              )
            else ...[
              const _SectionTitle('Popular'),

              if (loadingTracks)
                SliverList.builder(
                  itemCount: 5,
                  itemBuilder: (context, i) => TrackItemSkeleton(index: i + 1),
                )
              else if (tracks.isEmpty)
                const SliverToBoxAdapter(
                  child: _Empty('No tracks for this artist'),
                )
              else
                SliverList.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, i) => TrackItem(
                    index: i + 1,
                    title: shown[i].name,
                    imageUrl: shown[i].imageUrl,
                    albumName: shown[i].albumName,
                    duration: shown[i].duration,
                    trackId: shown[i].id,
                  ),
                ),

              if (tracks.length > 5 && !loadingTracks)
                SliverToBoxAdapter(
                  child: _MoreButton(
                    expanded: _showAllTracks,
                    onTap: () =>
                        setState(() => _showAllTracks = !_showAllTracks),
                  ),
                ),

              if (loadingTracks) ...[
                const _SectionTitle('Albums'),
                const AlbumGridSkeleton(),
              ] else ...[
                if (discography.fullAlbums.isNotEmpty) ...[
                  const _SectionTitle('Albums'),
                  AlbumGrid(albums: discography.fullAlbums),
                ],
                if (discography.singles.isNotEmpty) ...[
                  const _SectionTitle('Singles & EPs'),
                  AlbumGrid(albums: discography.singles),
                ],
              ],
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),

        // Wide windows navigate back from the sidebar, so the floating button
        // would be a second control for the same thing.
        if (!context.isWide) ArtistBackButton(scrollOffset: _scrollOffset),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.pagePadding + 8,
          28,
          context.pagePadding,
          12,
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _MoreButton({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.pagePadding + 8),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          ),
          child: Text(
            expanded ? 'Show less' : 'See more',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xCCFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;

  const _Empty(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.pagePadding,
        vertical: 24,
      ),
      child: Text(message, style: const TextStyle(color: Colors.white54)),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadFailed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.white38, size: 40),
          const SizedBox(height: 12),
          const Text(
            "Couldn't load this artist",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: const Color(0xff1BD760)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
