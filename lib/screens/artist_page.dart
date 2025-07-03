import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rick_spot/models/artist_album.dart';
import 'package:rick_spot/models/artist_track.dart';
import 'package:rick_spot/providers/searchbar_provider.dart';
import 'package:rick_spot/services/artist_service.dart';
import 'package:rick_spot/services/color_extractor.dart';
import 'package:rick_spot/widgets/artist_page/album_grid.dart';
import 'package:rick_spot/widgets/artist_page/artist_header.dart';
import 'package:rick_spot/widgets/artist_page/back_button.dart';
import 'package:rick_spot/widgets/artist_page/best_track_item.dart';
import 'package:rick_spot/widgets/bottom_player.dart';

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
  Color _dominantColor = Color(0xff491d18); // Default color until we extract
  bool _isLoadingColor = true;
  bool _isLoadingData = true;
  bool _hasError = false;
  String _errorMessage = '';

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _showAllTracks = false; // Flag to control track visibility

  List<ArtistTrack> _tracks = [];
  List<ArtistAlbum> _albums = [];

  // Placeholder data for skeleton loading
  final List<Map<String, String>> _placeholderTracks = List.generate(
    5,
    (index) => {"title": "Loading track...", "duration": "0:00"},
  );

  final List<Map<String, String>> _placeholderAlbums = List.generate(
    6,
    (index) => {
      "title": "Loading album...",
      "releaseDate": "2023",
      "trackCount": "0 tracks",
      "image": "",
    },
  );

  @override
  void initState() {
    super.initState();
    _extractColor();
    _fetchArtistData();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  Future<void> _fetchArtistData() async {
    try {
      setState(() {
        _isLoadingData = true;
        _hasError = false;
      });

      final data = await ArtistService.getArtistDiscography(widget.artistId);

      if (mounted) {
        setState(() {
          _tracks = data['tracks'] as List<ArtistTrack>;
          _albums = data['albums'] as List<ArtistAlbum>;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _hasError = true;
          _errorMessage = 'Failed to load artist data: $e';
        });
        print(_errorMessage);
      }
    }
  }

  Future<void> _extractColor() async {
    if (widget.artistImage.isEmpty) {
      setState(() {
        _isLoadingColor = false;
      });
      return;
    }

    try {
      final imageProvider = NetworkImage(widget.artistImage);
      final extractedColor = await ColorExtractor.extractDominantColor(
        imageProvider,
      );

      if (mounted) {
        setState(() {
          _dominantColor = extractedColor;
          _isLoadingColor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingColor = false;
        });
      }
      print('Error extracting color: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the keyboard visibility state from provider
    final searchState = ref.watch(searchStateProvider);
    final showBottomPlayer = !searchState.isKeyboardVisible;

    // Determine how many tracks to display
    final displayedTracks =
        _showAllTracks
            ? _tracks
            : _tracks.length > 5
            ? _tracks.sublist(0, 5)
            : _tracks;

    // Format albums for the grid
    final formattedAlbums =
        _albums.map((album) {
          return {
            "title": album.name,
            "releaseDate": _formatReleaseDate(album.releaseDate),
            "trackCount": "${album.totalTracks} tracks",
            "image": album.imageUrl,
          };
        }).toList();

    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Stack(
        children: [
          // Always show the scrollable content with at least the artist header
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Artist banner with gradient background - always visible
              SliverToBoxAdapter(
                child: ArtistHeader(
                  artistName: widget.artistName,
                  artistImage: widget.artistImage,
                  dominantColor: _dominantColor,
                ),
              ),

              // Popular section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Popular",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: Gap(12)),

              // Popular tracks list with skeleton loading
              _hasError
                  ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 24.0,
                      ),
                      child: Text(
                        "Failed to load tracks",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                  : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (_isLoadingData) {
                        // Skeleton version with visible track numbers
                        return _buildTrackSkeleton(index + 1);
                      } else {
                        if (index >= displayedTracks.length) return null;
                        // Real data with trackId passed to TrackItem
                        return TrackItem(
                          index: index + 1,
                          title: displayedTracks[index].name,
                          imageUrl: displayedTracks[index].imageUrl,
                          duration: displayedTracks[index].duration,
                          trackId:
                              displayedTracks[index].id, // Pass the track ID
                        );
                      }
                    }, childCount: _isLoadingData ? 5 : displayedTracks.length),
                  ),

              // See more / Show less button (only if there are more than 5 tracks)
              _tracks.length > 5 && !_isLoadingData
                  ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAllTracks = !_showAllTracks;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            _showAllTracks ? "Show less" : "See more",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xaaffffff),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  : SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Albums section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Albums",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Albums grid with skeleton loading
              SliverToBoxAdapter(
                child:
                    _isLoadingData
                        ? _buildAlbumGridSkeleton()
                        : AlbumGrid(albums: formattedAlbums),
              ),

              // Bottom padding - increased to account for the bottom player
              SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),

          // Error overlay if needed
          if (_hasError && !_isLoadingData)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(
                        "Failed to load artist data",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: _fetchArtistData,
                        child: Text("Retry"),
                        style: TextButton.styleFrom(
                          foregroundColor: Color(0xff1BD760),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Fixed back button
          ArtistBackButton(scrollOffset: _scrollOffset),

          // Bottom player at the bottom of the screen - same as HomePage
          if (showBottomPlayer)
            Positioned(left: 0, right: 0, bottom: 0, child: BottomPlayer()),
        ],
      ),
    );
  }

  Widget _buildTrackSkeleton(int number) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
      child: Row(
        children: [
          // Track number - visible, not skeletonized
          SizedBox(
            width: 30,
            child: Text(
              "$number",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),

          // Album art skeleton
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(width: 40, height: 40, color: Color(0x5AFFFFFF)),
          ),

          SizedBox(width: 16),

          // Title skeleton
          Expanded(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: Color(0x5AFFFFFF),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          SizedBox(width: 16),

          // Duration skeleton
          Container(
            width: 35,
            height: 14,
            decoration: BoxDecoration(
              color: Color(0x5AFFFFFF),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumGridSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 16,
          mainAxisSpacing: 12,
        ),
        itemCount: 6, // Show 6 placeholder albums
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Album cover skeleton
              AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(color: Color(0x5AFFFFFF)),
                ),
              ),
              SizedBox(height: 8),
              // Album title skeleton
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: Color(0x5AFFFFFF),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 4),
              // Album info skeleton
              Container(
                width: double.infinity * 0.7,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0x5AFFFFFF),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatReleaseDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length >= 2) {
        final year = parts[0];
        final month = _getMonthName(int.parse(parts[1]));
        final day = parts.length > 2 ? parts[2] : '';
        return day.isNotEmpty ? "$day $month $year" : "$month $year";
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }
}
