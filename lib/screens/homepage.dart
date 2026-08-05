import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:spotACrack/providers/search_result_provider.dart';
import 'package:spotACrack/widgets/searchbar.dart';
import 'package:spotACrack/widgets/spotify_search_results.dart';
import 'package:spotACrack/providers/searchbar_provider.dart';
import 'package:spotACrack/utils/responsive.dart';
import 'package:spotACrack/widgets/skeletons/artist_tile_skeleton.dart';
import 'package:spotACrack/widgets/skeletons/horizontal_album_skeleton.dart';
import 'package:spotACrack/widgets/skeletons/result_tile_skeleton.dart';

// Debug logging
void _debug(String message) {
  print("HOME_DEBUG: $message");
}

/// Search tab. The app frame ([AppShell]) owns the Scaffold, the mini player
/// and the nav bar, so this only renders the search surface itself.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  // Keep a single instance of the SearchBar
  final GlobalKey<SearchbarState> _searchbarKey = GlobalKey<SearchbarState>();

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

    _debug(
      "Building HomePage - active=${searchState.isActive}, hasText=${searchState.hasText}, keyboardVisible=${searchState.isKeyboardVisible}",
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleBackgroundTap,
      child: Padding(
        padding:
            searchState.isActive || searchState.hasText
                ? EdgeInsets.zero
                : EdgeInsets.fromLTRB(
                  context.pagePadding,
                  24,
                  context.pagePadding,
                  0,
                ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showElements)
              Text(
                'Search',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: context.isWide ? 32 : 28,
                  letterSpacing: -0.5,
                ),
              ),

            if (showElements) const Gap(16),

            Searchbar(key: _searchbarKey),

            if (!showElements)
              Expanded(
                child: searchResults.isLoading
                    ? _buildLoadingSkeletons()
                    : searchResults.tracks.isEmpty &&
                            searchResults.albums.isEmpty
                        ? Center(
                            child: Text(
                              searchResults.error.isNotEmpty
                                  ? searchResults.error
                                  : 'No results found',
                              style: const TextStyle(color: Colors.white60),
                            ),
                          )
                        : const SpotifySearchResults(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeletons() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First track skeleton
          ResultTileSkeleton(),
          Gap(10),
          // Album horizontal scrollview skeleton
          HorizontalAlbumSkeleton(),

          // Artist tile skeleton
          ArtistTileSkeleton(),

          // More track skeletons
          ResultTileSkeleton(),
          ResultTileSkeleton(),
          ResultTileSkeleton(),
          ResultTileSkeleton(),
        ],
      ),
    );
  }
}
