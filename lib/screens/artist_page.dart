import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:rick_spot/services/color_extractor.dart';

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
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _dominantColor,
                        _dominantColor.withOpacity(0.8),
                        _dominantColor.withOpacity(0.6),
                        _dominantColor.withOpacity(0.3),
                        Color(
                          0xFF121212,
                        ), // Blend to the app's background color
                      ],
                      stops: [0.0, 0.2, 0.4, 0.7, 1.0],
                    ),
                  ),
                  child: Column(
                    children: [
                      // App bar space
                      SizedBox(height: MediaQuery.of(context).padding.top + 56),

                      // Artist image
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                        ), // Changed to 16px
                        child: Center(
                          child: Container(
                            width: 172,
                            height: 172,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child:
                                  widget.artistImage.isNotEmpty
                                      ? Image.network(
                                        widget.artistImage,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            color: Colors.grey[800],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: Color(0xff1BD760),
                                                value:
                                                    loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            (loadingProgress
                                                                    .expectedTotalBytes ??
                                                                1)
                                                        : null,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                      : Container(
                                        color: Colors.grey[800],
                                        child: Icon(
                                          Icons.person,
                                          size: 80,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Artist info and play button in a row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                        ), // Changed to 16px
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Artist name and listeners in a column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.artistName,
                                    style: TextStyle(
                                      fontSize:
                                          24, // Changed to 24px as requested
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "40,458,960 monthly listeners",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Play button
                            Container(
                              width: 56, // Changed to 56px as requested
                              height: 56, // Changed to 56px as requested
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xff1BD760),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.play_arrow,
                                  size: 32,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Playing ${widget.artistName}',
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 48),
                    ],
                  ),
                ),
              ),

              // Popular section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ), // Changed to 16px
                  child: Text(
                    "Popular",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // List of songs will go here
              SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Placeholder for songs
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // This is just a placeholder - you'll replace with actual songs
                    final songs = [
                      {"title": "Can't Stop", "duration": "4:29"},
                      {"title": "Californication", "duration": "5:29"},
                      {"title": "Scar Tissue", "duration": "3:35"},
                      {"title": "Under the Bridge", "duration": "4:24"},
                      {"title": "Otherside", "duration": "4:15"},
                    ];

                    if (index >= songs.length) return null;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, // Changed to 16px
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          // Song number
                          SizedBox(
                            width: 30,
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ),

                          // Album art placeholder
                          Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[800],
                          ),

                          SizedBox(width: 16),

                          // Song title
                          Expanded(
                            child: Text(
                              songs[index]["title"]!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // Verified icon
                          Icon(
                            Icons.check_circle,
                            color: Color(0xff1BD760),
                            size: 16,
                          ),

                          SizedBox(width: 16),

                          // Duration
                          Text(
                            songs[index]["duration"]!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: 5, // Placeholder count
                ),
              ),

              // Bottom padding
              SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Fixed back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      _scrollOffset > 200
                          ? Colors.black.withOpacity(0.5)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/back_arrow.svg',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
