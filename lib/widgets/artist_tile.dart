import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

class ArtistTile extends StatefulWidget {
  final String artistId;
  final String? artistName; // Add optional artistName parameter

  const ArtistTile({
    super.key,
    required this.artistId,
    this.artistName, // Optional parameter for the artist name
  });

  @override
  State<ArtistTile> createState() => _ArtistTileState();
}

class _ArtistTileState extends State<ArtistTile> {
  late Dio _dio;

  bool _isLoading = true;
  late String _artistName;
  String _imageUrl = "";
  bool _isVerified = false;
  String? _currentArtistId;

  @override
  void initState() {
    super.initState();
    // Initialize artist name with provided value or default
    _artistName = widget.artistName ?? "Loading...";

    // Configure Dio with no caching
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: 5),
        receiveTimeout: Duration(seconds: 5),
        headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
      ),
    );

    _currentArtistId = widget.artistId;
    _fetchArtistData();
  }

  @override
  void didUpdateWidget(ArtistTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the artistId prop has changed
    if (oldWidget.artistId != widget.artistId) {
      print(
        'ArtistTile: artistId changed from ${oldWidget.artistId} to ${widget.artistId}',
      );

      // Reset state and fetch new data
      setState(() {
        _isLoading = true;
        _artistName =
            widget.artistName ?? "Loading..."; // Use provided name or default
        _imageUrl = "";
        _isVerified = false;
        _currentArtistId = widget.artistId;
      });

      _fetchArtistData();
    }
  }

  Future<void> _fetchArtistData() async {
    try {
      print('ArtistTile: Fetching data for artist ID: ${widget.artistId}');

      // Clear any previous cached responses
      final url = 'https://spc.rickyscloud.com/api/artist/${widget.artistId}';

      final response = await _dio.get(
        url,
        options: Options(
          // Ensure we're not getting cached responses
          extra: {'refresh': true},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print(
          'ArtistTile: Received data for ${data['name']} (ID: ${data['id']})',
        );

        // Get the smallest image (last one in the array)
        final List<dynamic> images = data['images'] ?? [];
        final String imageUrl = images.isNotEmpty ? images.last['url'] : "";

        // Determine if the artist is verified (popularity > 60)
        final int popularity = data['popularity'] ?? 0;

        // Only update state if this is still the current artist
        if (_currentArtistId == widget.artistId) {
          setState(() {
            // Only update name if it wasn't provided as a prop
            if (widget.artistName == null) {
              _artistName = data['name'] ?? "Unknown Artist";
            }
            _imageUrl = imageUrl;
            _isLoading = false;
            _isVerified = popularity > 60;
          });
        }
      }
    } catch (e) {
      print('Error fetching artist data for ID ${widget.artistId}: $e');
      // Only update state if this is still the current artist
      if (_currentArtistId == widget.artistId && widget.artistName == null) {
        setState(() {
          _artistName = "Error loading artist";
          _isLoading = false;
        });
      } else if (_currentArtistId == widget.artistId) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to artist page with artist name
        context.push('/artist/${widget.artistId}?name=$_artistName');
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Artist image with loading state
            ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child:
                  _isLoading || _imageUrl.isEmpty
                      ? Container(
                        height: 48,
                        width: 48,
                        color: Color(0x6affffff),
                        child: Center(
                          child:
                              _isLoading
                                  ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white70,
                                    ),
                                  )
                                  : Icon(Icons.person, color: Colors.white70),
                        ),
                      )
                      : Image.network(
                        _imageUrl,
                        height: 48,
                        width: 48,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 48,
                            width: 48,
                            color: Colors.grey[800],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                                value:
                                    loadingProgress.expectedTotalBytes != null
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
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 48,
                            width: 48,
                            color: Colors.grey[800],
                            child: Icon(Icons.person, color: Colors.white70),
                          );
                        },
                      ),
            ),
            Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _artistName,
                          style: TextStyle(fontSize: 17, letterSpacing: -0.2),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Gap(8),
                      // Only show verified icon if the artist is verified
                      if (_isVerified && !_isLoading)
                        SvgPicture.asset(
                          'assets/icons/verified.svg',
                          color: Color(0xff4BB3FF),
                        ),
                    ],
                  ),
                  Text(
                    "Artist",
                    style: TextStyle(
                      color: Color(0xaaffffff),
                      fontSize: 13,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Cancel any pending requests when the widget is disposed
    _dio.close();
    super.dispose();
  }
}
