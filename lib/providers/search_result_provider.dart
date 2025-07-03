import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rick_spot/repositories/search_repository.dart';
import 'package:rick_spot/widgets/horizontal_album_scroller.dart';

// Search state model
class SearchResultsState {
  final bool isLoading;
  final List<Album> albums;
  final List<Map<String, dynamic>> tracks;
  final String query;
  final String error;

  SearchResultsState({
    this.isLoading = false,
    this.albums = const [],
    this.tracks = const [],
    this.query = '',
    this.error = '',
  });

  SearchResultsState copyWith({
    bool? isLoading,
    List<Album>? albums,
    List<Map<String, dynamic>>? tracks,
    String? query,
    String? error,
  }) {
    return SearchResultsState(
      isLoading: isLoading ?? this.isLoading,
      albums: albums ?? this.albums,
      tracks: tracks ?? this.tracks,
      query: query ?? this.query,
      error: error ?? this.error,
    );
  }
}

// Search notifier
class SearchResultsNotifier extends StateNotifier<SearchResultsState> {
  final SearchRepository _searchRepository;

  SearchResultsNotifier(this._searchRepository) : super(SearchResultsState());

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = SearchResultsState();
      return;
    }

    // Don't search if the query is too short
    if (query.length < 2) {
      return;
    }

    // Debounce by checking if we're already loading the same query
    if (state.isLoading && state.query == query) {
      return;
    }

    state = state.copyWith(isLoading: true, query: query);

    try {
      final results = await _searchRepository.search(query);

      // Parse albums
      final List<Album> albums =
          (results['albums'] as List<dynamic>)
              .map(
                (album) => Album(
                  artist: album['artist'] as String,
                  artistId: album['artist_id'] as String,
                  id: album['id'] as String,
                  imageUri: album['image_uri'] as String,
                  name: album['name'] as String,
                ),
              )
              .toList();

      // Parse tracks
      final List<Map<String, dynamic>> tracks =
          (results['tracks'] as List<dynamic>).map((track) {
            // Remove quotes from album_id and album_name if they exist
            String albumId = track['album_id'] as String;
            String albumName = track['album_name'] as String;

            if (albumId.startsWith('"') && albumId.endsWith('"')) {
              albumId = albumId.substring(1, albumId.length - 1);
            }

            if (albumName.startsWith('"') && albumName.endsWith('"')) {
              albumName = albumName.substring(1, albumName.length - 1);
            }

            return {
              'albumId': albumId,
              'albumName': albumName,
              'artist': track['artist'] as String,
              'artistId': track['artist_id'] as String,
              'duration': track['duration'] as int,
              'id': track['id'] as String,
              'imageUri': track['image_uri'] as String,
              'name': track['name'] as String,
            };
          }).toList();

      state = state.copyWith(
        isLoading: false,
        albums: albums,
        tracks: tracks,
        error: '',
      );
    } catch (e) {
      print('Error in search: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to search: $e');
    }
  }

  void clearSearch() {
    state = SearchResultsState();
  }
}

// Provider
final searchResultsProvider =
    StateNotifierProvider<SearchResultsNotifier, SearchResultsState>((ref) {
      final searchRepository = ref.watch(searchRepositoryProvider);
      return SearchResultsNotifier(searchRepository);
    });
