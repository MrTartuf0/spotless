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

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchStateProvider);
    final showElements = !searchState.isActive && !searchState.hasText;

    _debug(
      "Building HomePage - active=${searchState.isActive}, hasText=${searchState.hasText}",
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Only handle taps outside the search area
      onTap: () {
        _debug("Tap outside detected");

        // Only unfocus and hide keyboard
        _searchbarKey.currentState?.unfocusWithoutStateChange();

        // Only reset search state if there's no text
        if (!searchState.hasText) {
          _debug("No text, deactivating search");
          ref.read(searchStateProvider.notifier).setActive(false);
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Stack(
          children: [
            BottomPlayer(),
            SafeArea(
              child: Padding(
                padding:
                    searchState.isActive || searchState.hasText
                        ? EdgeInsets.zero
                        : EdgeInsets.fromLTRB(16, 48, 16, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // // Debug indicator
                    // Container(
                    //   padding: EdgeInsets.symmetric(vertical: 4),
                    //   child: Text(
                    //     "DEBUG: active=${searchState.isActive}, hasText=${searchState.hasText}",
                    //     style: TextStyle(color: Colors.grey, fontSize: 10),
                    //   ),
                    // ),

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
                          child: Column(
                            children: [
                              ResultTile(),
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
                              ResultTile(),
                              ResultTile(),
                              ResultTile(),
                              ResultTile(),
                              ResultTile(),
                              ResultTile(),
                              ResultTile(),
                              ResultTile(),
                              ResultTile(),
                              ResultTile(),
                              ResultTile(),
                              ResultTile(),
                              ResultTile(),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Buttons
                    // if (showElements) ...[
                    //   Gap(16),
                    //   ElevatedButton(
                    //     onPressed: () {
                    //       final audioNotifier = ref.read(
                    //         audioPlayerProvider.notifier,
                    //       );
                    //       audioNotifier.loadTrack('2aibwv5hGXSgw7Yru8IYTO');

                    //       ScaffoldMessenger.of(context).showSnackBar(
                    //         SnackBar(
                    //           content: Text(
                    //             'Loading track...',
                    //             style: TextStyle(color: Colors.black),
                    //           ),
                    //           duration: Duration(seconds: 1),
                    //           backgroundColor: Color(0xff1BD760),
                    //         ),
                    //       );
                    //     },
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Color(0xff1BD760),
                    //       foregroundColor: Colors.black,
                    //       padding: EdgeInsets.symmetric(
                    //         horizontal: 20,
                    //         vertical: 12,
                    //       ),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(30),
                    //       ),
                    //     ),
                    //     child: Text('Play: 2aibwv5hGXSgw7Yru8IYTO'),
                    //   ),
                    //   ElevatedButton(
                    //     onPressed: () {
                    //       final audioNotifier = ref.read(
                    //         audioPlayerProvider.notifier,
                    //       );
                    //       audioNotifier.loadTrack('1AsNfUfuGmQGXbrjoPQl8j');

                    //       ScaffoldMessenger.of(context).showSnackBar(
                    //         SnackBar(
                    //           content: Text(
                    //             'Loading track...',
                    //             style: TextStyle(color: Colors.black),
                    //           ),
                    //           duration: Duration(seconds: 1),
                    //           backgroundColor: Color(0xff1BD760),
                    //         ),
                    //       );
                    //     },
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Color(0xff1BD760),
                    //       foregroundColor: Colors.black,
                    //       padding: EdgeInsets.symmetric(
                    //         horizontal: 20,
                    //         vertical: 12,
                    //       ),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(30),
                    //       ),
                    //     ),
                    //     child: Text('Play: 1AsNfUfuGmQGXbrjoPQl8j'),
                    //   ),
                    // ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
