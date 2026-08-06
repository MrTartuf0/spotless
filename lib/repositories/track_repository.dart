// lib/repositories/track_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:spotACrack/models/album.dart';
import 'package:spotACrack/models/lyrics.dart';

class TrackRepository {
  final Dio _dio;
  final String _baseUrl = 'https://spc.rickyscloud.com';

  TrackRepository({Dio? dio}) : _dio = dio ?? _createDio();

  // Factory method to create and configure Dio with logger
  static Dio _createDio() {
    final dio = Dio();

    // Add pretty logger
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: true,
        compact: false,
        error: true,
        maxWidth: 90,
      ),
    );

    return dio;
  }

  Future<Map<String, dynamic>> getTrack(String trackId) async {
    try {
      final response = await _dio.get('$_baseUrl/api/track/$trackId');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load track data');
      }
    } catch (e) {
      print('Error fetching track data: $e');
      throw Exception('Error fetching track data: $e');
    }
  }

  Future<String> getHlsUrl(String trackId) async {
    try {
      final response = await _dio.get('$_baseUrl/api/hls/$trackId');

      if (response.statusCode == 200 && response.data['url'] != null) {
        return '$_baseUrl${response.data['url']}';
      } else {
        throw Exception('Failed to get stream URL');
      }
    } catch (e) {
      print('Error getting HLS URL, falling back to direct stream: $e');
      return getDirectStreamUrl(trackId);
    }
  }

  String getDirectStreamUrl(String trackId) => '$_baseUrl/api/play/$trackId';

  Future<Album> getAlbum(String albumId) async {
    final response = await _dio.get('$_baseUrl/api/album/$albumId');
    if (response.statusCode == 200) {
      return Album.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to load album $albumId');
  }

  /// Spotify's autoplay station for a track: the tracks the desktop client
  /// would play next, in the order they are meant to be played.
  ///
  /// [recent] biases the station away from repeating tracks just played.
  /// Returns an empty list on failure so callers can fall back.
  Future<List<String>> getRecommendations(
    String seedTrackId, {
    List<String> recent = const [],
    // Only ids are needed to choose what to play next, and each resolved track
    // costs the backend a metadata round trip, so ask it to resolve as few as
    // possible.
    int limit = 1,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/recommendations/$seedTrackId',
        queryParameters: {
          'limit': limit,
          // Only the tail matters, and the URL should not grow unbounded.
          if (recent.isNotEmpty) 'recent': recent.reversed.take(10).join(','),
        },
      );

      if (response.statusCode == 200) {
        // The full station comes back as bare ids; `tracks` only carries the
        // handful that were resolved. Prefer ids, fall back for older backends.
        final ids = response.data['ids'];
        if (ids is List) {
          return ids
              .map((id) => id as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
        }

        if (response.data['tracks'] is List) {
          return (response.data['tracks'] as List)
              .map((track) => track['id'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
        }
      }
      return const [];
    } catch (e) {
      print('Error fetching recommendations: $e');
      return const [];
    }
  }

  /// Same station as [getRecommendations], but with the metadata needed to
  /// render cards. The backend resolves artwork, so this is one request.
  Future<List<Map<String, dynamic>>> getRecommendedTracks(
    String seedTrackId, {
    int limit = 10,
    List<String> recent = const [],
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/recommendations/$seedTrackId',
        queryParameters: {
          'limit': limit,
          if (recent.isNotEmpty) 'recent': recent.reversed.take(10).join(','),
        },
      );

      if (response.statusCode == 200 && response.data['tracks'] is List) {
        return (response.data['tracks'] as List)
            .cast<Map<String, dynamic>>()
            .where((track) => (track['id'] as String? ?? '').isNotEmpty)
            .toList();
      }
      return const [];
    } catch (e) {
      print('Error fetching recommended tracks: $e');
      return const [];
    }
  }

  /// Time-synced lyrics for a track. A track with no lyrics comes back as
  /// [Lyrics.none] (a normal state, not an error), as does any failure — the
  /// lyrics view is non-essential and should never surface an error.
  Future<Lyrics> getLyrics(String trackId) async {
    try {
      final response = await _dio.get('$_baseUrl/api/lyrics/$trackId');
      if (response.statusCode == 200 && response.data is Map) {
        return Lyrics.fromJson((response.data as Map).cast<String, dynamic>());
      }
      return Lyrics.none(trackId);
    } catch (e) {
      print('Error fetching lyrics: $e');
      return Lyrics.none(trackId);
    }
  }

  Future<Map<String, dynamic>> getNextRandomSong(String trackId) async {
    try {
      print('Fetching next random song for track ID: $trackId');
      final response = await _dio.get(
        '$_baseUrl/api/random_song_by_artist/$trackId',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load next random song');
      }
    } catch (e) {
      print('Error fetching next random song: $e');
      throw Exception('Error fetching next random song: $e');
    }
  }

  // Keep this method for compatibility with existing code but implement it using the new method
  Future<Map<String, dynamic>> getRandomSongByArtist(String artistId) async {
    try {
      print('Fetching random song for artist ID: $artistId');
      final response = await _dio.get(
        '$_baseUrl/api/random_song_by_artist/$artistId',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load random song');
      }
    } catch (e) {
      print('Error fetching random song: $e');
      throw Exception('Error fetching random song: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchTracks(
    String query, {
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/search',
        queryParameters: {'q': query, 'limit': limit, 'type': 'track'},
      );

      if (response.statusCode == 200 && response.data['tracks'] != null) {
        // Process and format the results
        final List<dynamic> items = response.data['tracks']['items'];
        return items.map((item) {
          return {
            'id': item['id'],
            'name': item['name'],
            'artist': item['artists'][0]['name'],
            'artistId': item['artists'][0]['id'],
            'albumId': item['album']['id'],
            'albumName': item['album']['name'],
            'imageUri': item['album']['images'][0]['url'],
            'duration': _formatDuration(item['duration_ms']),
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error searching tracks: $e');
      return [];
    }
  }

  String _formatDuration(int milliseconds) {
    final int seconds = (milliseconds / 1000).floor();
    final int minutes = (seconds / 60).floor();
    final int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return TrackRepository();
});
