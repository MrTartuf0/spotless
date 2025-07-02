import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:rick_spot/services/color_extractor.dart';
import 'package:rick_spot/widgets/artist_page/album_grid.dart';
import 'package:rick_spot/widgets/artist_page/artist_header.dart';
import 'package:rick_spot/widgets/artist_page/back_button.dart';
import 'package:rick_spot/widgets/artist_page/best_track_item.dart';

class ArtistPage extends StatefulWidget {
  final String artistId;
  final String artistName;
  final String artistImage;

  const ArtistPage({
    Key? key,
    required this.artistId,
    required this.artistName,
    this.artistImage = '',
  }) : super(key: key);

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  Color _dominantColor = Color(0xff491d18); // Default color until we extract
  bool _isLoadingColor = true;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _showAllTracks = false; // Flag to control track visibility

  @override
  void initState() {
    super.initState();
    _extractColor();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
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
    // Complete list of songs
    final allSongs = [
      {"title": "Can't Stop", "duration": "4:29"},
      {"title": "Californication", "duration": "5:29"},
      {"title": "Scar Tissue", "duration": "3:35"},
      {"title": "Under the Bridge", "duration": "4:24"},
      {"title": "Otherside", "duration": "4:15"},
      // 5 more songs
      {"title": "Snow (Hey Oh)", "duration": "5:34"},
      {"title": "Dani California", "duration": "4:42"},
      {"title": "By the Way", "duration": "3:37"},
      {"title": "Dark Necessities", "duration": "5:02"},
      {"title": "Give It Away", "duration": "4:43"},
    ];

    // Determine how many songs to display
    final displayedSongs = _showAllTracks ? allSongs : allSongs.sublist(0, 5);

    // Album data
    final albums = [
      {
        "title": "Return of the Dream Canteen",
        "releaseDate": "14 Oct 2022",
        "trackCount": "17 tracks",
        "image":
            "https://i.scdn.co/image/ab67616d0000b273f2f2f436e9e2d3a3535e7617",
      },
      {
        "title": "Unlimited Love",
        "releaseDate": "1 Apr 2022",
        "trackCount": "17 tracks",
        "image":
            "https://i.scdn.co/image/ab67616d0000b273a5a0567b3d2444014d05970f",
      },
      {
        "title": "The Getaway",
        "releaseDate": "17 Jun 2016",
        "trackCount": "13 tracks",
        "image":
            "https://i.scdn.co/image/ab67616d0000b273a9249ebb15eaaba3e587f97b",
      },
      {
        "title": "I'm with You",
        "releaseDate": "29 Aug 2011",
        "trackCount": "14 tracks",
        "image":
            "https://i.scdn.co/image/ab67616d0000b273118f865acfba94d53bf617b3",
      },
      {
        "title": "Stadium Arcadium",
        "releaseDate": "5 May 2006",
        "trackCount": "28 tracks",
        "image":
            "https://i.scdn.co/image/ab67616d0000b273a9249ebb15eaaba3e587f97b",
      },
      {
        "title": "By the Way",
        "releaseDate": "9 Jul 2002",
        "trackCount": "16 tracks",
        "image":
            "https://i.scdn.co/image/ab67616d0000b273de1af2785a83cc660155a0c4",
      },
    ];

    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Artist banner with gradient background
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

              // Popular tracks list
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index >= displayedSongs.length) return null;
                  return TrackItem(
                    index: index + 1,
                    title: displayedSongs[index]["title"]!,
                    duration: displayedSongs[index]["duration"]!,
                  );
                }, childCount: displayedSongs.length),
              ),

              // See more / Show less button
              SliverToBoxAdapter(
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
              ),

              // Albums section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16),
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

              // Albums grid
              SliverToBoxAdapter(child: AlbumGrid(albums: albums)),

              // Bottom padding
              SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Fixed back button
          ArtistBackButton(scrollOffset: _scrollOffset),
        ],
      ),
    );
  }
}
