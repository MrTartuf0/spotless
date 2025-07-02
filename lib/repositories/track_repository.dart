// lib/repositories/track_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

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

  Future<String> getStreamUrl(String trackId) async {
    try {
      // Try to get the HLS stream URL
      final response = await _dio.get('$_baseUrl/api/hls/$trackId');

      if (response.statusCode == 200 && response.data['url'] != null) {
        // Prepend the base URL to the relative URL returned by the API
        return '$_baseUrl${response.data['url']}';
      } else {
        throw Exception('Failed to get stream URL');
      }
    } catch (e) {
      print('Error getting stream URL: $e');

      // Fallback to the default URL if there's an error
      return '$_baseUrl/hls/94599360893856627734266258834711005588.m3u8';
    }
  }

  // Updated method to get a random song - uses the track ID instead of artist ID
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
