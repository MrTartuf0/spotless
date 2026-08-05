import 'package:dio/dio.dart';
import 'package:spotACrack/models/artist_album.dart';
import 'package:spotACrack/models/artist_profile.dart';
import 'package:spotACrack/models/artist_track.dart';

/// An artist's popular tracks plus everything they released.
class Discography {
  final List<ArtistTrack> tracks;
  final List<ArtistAlbum> albums;

  const Discography({this.tracks = const [], this.albums = const []});

  /// Full-length albums, newest first.
  List<ArtistAlbum> get fullAlbums => _sorted(albums.where((a) => a.isAlbum));

  /// Singles, EPs and compilations — everything the albums grid leaves out.
  List<ArtistAlbum> get singles => _sorted(albums.where((a) => !a.isAlbum));

  static List<ArtistAlbum> _sorted(Iterable<ArtistAlbum> source) {
    final list = source.toList()
      ..sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    return list;
  }
}

class ArtistService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );

  /// Name, artwork, followers and genres for the artist page header.
  static Future<ArtistProfile> getArtist(String artistId) async {
    try {
      final response = await _dio.get(
        'https://spc.rickyscloud.com/api/artist/$artistId',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load artist: ${response.statusCode}');
      }
      return ArtistProfile.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(_describe(e));
    }
  }

  static Future<Discography> getArtistDiscography(String artistId) async {
    try {
      final response = await _dio.get(
        'https://spc.rickyscloud.com/api/discography/$artistId',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load artist data: ${response.statusCode}');
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data as Map,
      );

      final tracks = ((data['tracks'] as List?) ?? const [])
          .map((track) => ArtistTrack.fromJson(track))
          .toList();

      // Singles and compilations are kept here and split out by [Discography];
      // the artist page shows them in their own section.
      final albums = ((data['albums'] as List?) ?? const [])
          .map((album) => ArtistAlbum.fromJson(album))
          .toList();

      return Discography(tracks: tracks, albums: albums);
    } on DioException catch (e) {
      throw Exception(_describe(e));
    } catch (e) {
      throw Exception('Failed to fetch artist data: $e');
    }
  }

  static String _describe(DioException e) {
    if (e.response != null) {
      return 'Server error: ${e.response?.statusCode} - '
          '${e.response?.statusMessage}';
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout => 'Connection timeout',
      DioExceptionType.receiveTimeout => 'Receive timeout',
      _ => 'Request failed: ${e.message}',
    };
  }
}
