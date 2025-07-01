import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:rick_spot/providers/search_result_provider.dart';
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
    final searchResults = ref.watch(searchResultsProvider);
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
                          child:
                              searchResults.isLoading
                                  ? Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xff1BD760),
                                    ),
                                  )
                                  : searchResults.tracks.isEmpty &&
                                      searchResults.albums.isEmpty
                                  ? Center(
                                    child: Text(
                                      searchResults.error.isNotEmpty
                                          ? searchResults.error
                                          : 'No results found',
                                      style: TextStyle(color: Colors.white60),
                                    ),
                                  )
                                  : SingleChildScrollView(
                                    // Add padding at the bottom when results are shown to account for player
                                    padding: EdgeInsets.only(
                                      bottom:
                                          80, // Always add padding for bottom player
                                    ),
                                    child: Column(
                                      children: [
                                        // First track at the top
                                        if (searchResults.tracks.isNotEmpty)
                                          ResultTile(
                                            albumId:
                                                searchResults
                                                    .tracks[0]['albumId'],
                                            albumName:
                                                searchResults
                                                    .tracks[0]['albumName'],
                                            artist:
                                                searchResults
                                                    .tracks[0]['artist'],
                                            artistId:
                                                searchResults
                                                    .tracks[0]['artistId'],
                                            duration:
                                                searchResults
                                                    .tracks[0]['duration'],
                                            id: searchResults.tracks[0]['id'],
                                            imageUri:
                                                searchResults
                                                    .tracks[0]['imageUri'],
                                            name:
                                                searchResults.tracks[0]['name'],
                                          ),

                                        // Albums in horizontal scrollview
                                        if (searchResults.albums.isNotEmpty)
                                          HorizontalAlbumScroller(
                                            albums: searchResults.albums,
                                          ),

                                        // Remaining tracks
                                        if (searchResults.tracks.length > 1)
                                          ...searchResults.tracks
                                              .skip(1)
                                              .map(
                                                (track) => ResultTile(
                                                  albumId: track['albumId'],
                                                  albumName: track['albumName'],
                                                  artist: track['artist'],
                                                  artistId: track['artistId'],
                                                  duration: track['duration'],
                                                  id: track['id'],
                                                  imageUri: track['imageUri'],
                                                  name: track['name'],
                                                ),
                                              )
                                              .toList(),
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
