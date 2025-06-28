// lib/repositories/track_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrackRepository {
  final Dio _dio;
  final String _baseUrl = 'https://spc.rickyscloud.com';

  TrackRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future<Map<String, dynamic>> getTrack(String trackId) async {
    try {
      final response = await _dio.get('$_baseUrl/api/track/$trackId');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load track data');
      }
    } catch (e) {
      throw Exception('Error fetching track data: $e');
    }
  }

  Future<String> getStreamUrl(String trackId) async {
    try {
      // Use the correct endpoint to get the HLS stream URL
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
}

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return TrackRepository();
});
