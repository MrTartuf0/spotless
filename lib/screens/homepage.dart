import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:rick_spot/widgets/bottom_player.dart';
import 'package:rick_spot/widgets/horizontal_album_scroller.dart';
import 'package:rick_spot/widgets/result_tile.dart';
import 'package:rick_spot/widgets/searchbar.dart';
import 'package:rick_spot/widgets/sheet_player.dart';
import 'package:rick_spot/providers/audio_player_provider.dart';
import 'package:rick_spot/providers/searchbar_provider.dart';

// Debug logging
void _debug(String message) {
  print("HOME_DEBUG: $message");
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // Keep a single instance of the SearchBar
  final GlobalKey<SearchbarState> _searchbarKey = GlobalKey<SearchbarState>();

  // Create a key for the bottom player to access it directly
  final GlobalKey _bottomPlayerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Force keyboard visibility to false initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchStateProvider.notifier).setKeyboardVisible(false);
    });
  }

  // Handle taps on empty spaces (background) of the page
  void _handleBackgroundTap() {
    _debug("Background tap detected");

    // Only unfocus and hide keyboard
    _searchbarKey.currentState?.unfocusWithoutStateChange();

    // Explicitly set keyboard visibility to false
    ref.read(searchStateProvider.notifier).setKeyboardVisible(false);

    // Only reset search state if there's no text
    if (!ref.read(searchStateProvider).hasText) {
      _debug("No text, deactivating search");
      ref.read(searchStateProvider.notifier).setActive(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchStateProvider);
    final showElements = !searchState.isActive && !searchState.hasText;

    // Only hide the bottom player when the keyboard is ACTUALLY visible
    final showBottomPlayer = !searchState.isKeyboardVisible;

    _debug(
      "Building HomePage - active=${searchState.isActive}, hasText=${searchState.hasText}, keyboardVisible=${searchState.isKeyboardVisible}",
    );

    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Stack(
        children: [
          // Main content with gesture detector for background taps only
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _handleBackgroundTap,
              child: SafeArea(
                bottom: false, // No bottom padding - we'll handle it ourselves
                child: Padding(
                  padding:
                      searchState.isActive || searchState.hasText
                          ? EdgeInsets.zero
                          : EdgeInsets.fromLTRB(16, 48, 16, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      if (showElements)
                        Text(
                          'Search',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),

                      if (showElements) Gap(16),

                      // Searchbar with a persistent key
                      Searchbar(key: _searchbarKey),

                      if (!showElements) ...[
                        Expanded(
                          child: SingleChildScrollView(
                            // Add padding at the bottom when results are shown to account for player
                            padding: EdgeInsets.only(
                              bottom:
                                  80, // Always add padding for bottom player
                            ),
                            child: Column(
                              children: [
                                // ResultTile widgets now handle their own keyboard visibility
                                ResultTile(
                                  albumId: "6deiaArbeoqp1xPEGdEKp1",
                                  albumName: "By the Way (Deluxe Edition)",
                                  artist: "Red Hot Chili Peppers",
                                  artistId: "0L8ExT028jH3ddEcZwqJJ5",
                                  duration: 269000,
                                  id: "3ZOEytgrvLwQaqXreDs2Jx",
                                  imageUri:
                                      "https://i.scdn.co/image/ab67616d0000b273de1af2785a83cc660155a0c4",
                                  name: "Can't Stop",
                                ),

                                // HorizontalAlbumScroller also handles keyboard visibility
                                HorizontalAlbumScroller(
                                  albums: [
                                    Album(
                                      artist: "Red Hot Chili Peppers",
                                      artistId: "0L8ExT028jH3ddEcZwqJJ5",
                                      id: "53tvjWbVNZKd3CvpENkzOC",
                                      imageUri:
                                          "https://i.scdn.co/image/ab67616d0000b2735590b4ee88187cb06a5b102d",
                                      name: "Greatest Hits",
                                    ),
                                    Album(
                                      artist: "Red Hot Chili Peppers",
                                      artistId: "0L8ExT028jH3ddEcZwqJJ5",
                                      id: "2Y9IRtehByVkegoD7TcLfi",
                                      imageUri:
                                          "https://i.scdn.co/image/ab67616d0000b27394d08ab63e57b0cae74e8595",
                                      name: "Californication (Deluxe Edition)",
                                    ),
                                    Album(
                                      artist: "Red Hot Chili Peppers",
                                      artistId: "0L8ExT028jH3ddEcZwqJJ5",
                                      id: "30Perjew8HyGkdSmqguYyg",
                                      imageUri:
                                          "https://i.scdn.co/image/ab67616d0000b273153d79816d853f2694b2cc70",
                                      name:
                                          "Blood Sugar Sex Magik (Deluxe Edition)",
                                    ),
                                    Album(
                                      artist: "Red Hot Chili Peppers",
                                      artistId: "0L8ExT028jH3ddEcZwqJJ5",
                                      id: "6deiaArbeoqp1xPEGdEKp1",
                                      imageUri:
                                          "https://i.scdn.co/image/ab67616d0000b273de1af2785a83cc660155a0c4",
                                      name: "By the Way (Deluxe Edition)",
                                    ),
                                    Album(
                                      artist: "Red Hot Chili Peppers",
                                      artistId: "0L8ExT028jH3ddEcZwqJJ5",
                                      id: "2ITVvrNiINKRiW7wA3w6w6",
                                      imageUri:
                                          "https://i.scdn.co/image/ab67616d0000b27397a52e0aeda9d95fb881c56d",
                                      name: "Unlimited Love",
                                    ),
                                  ],
                                ),

                                ResultTile(
                                  albumId: "2Y9IRtehByVkegoD7TcLfi",
                                  albumName: "Californication (Deluxe Edition)",
                                  artist: "Red Hot Chili Peppers",
                                  artistId: "0L8ExT028jH3ddEcZwqJJ5",
                                  duration: 329733,
                                  id: "48UPSzbZjgc449aqz8bxox",
                                  imageUri:
                                      "https://i.scdn.co/image/ab67616d0000b27394d08ab63e57b0cae74e8595",
                                  name: "Californication",
                                ),
                                ResultTile(
                                  albumId: "7xl50xr9NDkd3i2kBbzsNZ",
                                  albumName: "Stadium Arcadium",
                                  artist: "Red Hot Chili Peppers",
                                  artistId: "0L8ExT028jH3ddEcZwqJJ5",
                                  duration: 334666,
                                  id: "2aibwv5hGXSgw7Yru8IYTO",
                                  imageUri:
                                      "https://i.scdn.co/image/ab67616d0000b27309fd83d32aee93dceba78517",
                                  name: "Snow (Hey Oh)",
                                ),
                                ResultTile(
                                  albumId: "2Y9IRtehByVkegoD7TcLfi",
                                  albumName: "Californication (Deluxe Edition)",
                                  artist: "Red Hot Chili Peppers",
                                  artistId: "0L8ExT028jH3ddEcZwqJJ5",
                                  duration: 255373,
                                  id: "64BbK9SFKH2jk86U3dGj2P",
                                  imageUri:
                                      "https://i.scdn.co/image/ab67616d0000b27394d08ab63e57b0cae74e8595",
                                  name: "Otherside",
                                ),
                                ResultTile(
                                  albumId: "30Perjew8HyGkdSmqguYyg",
                                  albumName:
                                      "Blood Sugar Sex Magik (Deluxe Edition)",
                                  artist: "Red Hot Chili Peppers",
                                  artistId: "0L8ExT028jH3ddEcZwqJJ5",
                                  duration: 264306,
                                  id: "3d9DChrdc6BOeFsbrZ3Is0",
                                  imageUri:
                                      "https://i.scdn.co/image/ab67616d0000b273153d79816d853f2694b2cc70",
                                  name: "Under the Bridge",
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom player - always visible EXCEPT when keyboard is showing
          if (showBottomPlayer)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                elevation: 8,
                color: Colors.transparent,
                child: BottomPlayer(key: _bottomPlayerKey),
              ),
            ),
        ],
      ),
    );
  }
}
