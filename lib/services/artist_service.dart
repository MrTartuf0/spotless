import 'package:dio/dio.dart';
import 'package:rick_spot/models/artist_album.dart';
import 'package:rick_spot/models/artist_track.dart';

class ArtistService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );

  static Future<Map<String, dynamic>> getArtistDiscography(
    String artistId,
  ) async {
    try {
      final response = await _dio.get(
        'https://spc.rickyscloud.com/api/discography/$artistId',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;

        // Parse tracks
        final tracksList = data['tracks'] as List<dynamic>;
        final tracks =
            tracksList.map((track) => ArtistTrack.fromJson(track)).toList();

        // Parse albums - filter out singles if you want only albums
        final albumsList = data['albums'] as List<dynamic>;
        final albums =
            albumsList
                .where(
                  (album) => album['album_type'] == 'album',
                ) // Optional: filter only albums, not singles
                .map((album) => ArtistAlbum.fromJson(album))
                .toList();

        return {'tracks': tracks, 'albums': albums};
      } else {
        throw Exception('Failed to load artist data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Dio specific error handling
      if (e.response != null) {
        // The server responded with an error status code
        throw Exception(
          'Server error: ${e.response?.statusCode} - ${e.response?.statusMessage}',
        );
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Receive timeout');
      } else {
        throw Exception('Request failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to fetch artist data: $e');
    }
  }
}
