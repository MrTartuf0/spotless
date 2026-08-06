// lib/providers/audio_player/track_queue_service.dart
import 'package:spotACrack/repositories/track_repository.dart';

class TrackQueueService {
  final TrackRepository _trackRepository;

  TrackQueueService(this._trackRepository);

  // Everything streams through the segmented HLS endpoint. It starts playing
  // sooner and is seekable, where /api/play is one long chunked response.
  // getHlsUrl already falls back to the direct stream if the request fails.
  Future<String> _resolveStreamUrl(String trackId) {
    return _trackRepository.getHlsUrl(trackId);
  }

  /// Picks the single next track to play.
  ///
  /// Prefers Spotify's autoplay station for [currentTrackId], taking one track
  /// at a time: the first recommendation that has not been played yet. Falls
  /// back to the older random-by-artist endpoint if the station is empty.
  ///
  /// [exclude] is the set of already-played track ids, used both to bias the
  /// station and to skip candidates that would repeat.
  Future<Map<String, dynamic>> fetchNextTrack(
    String currentTrackId, {
    List<String> exclude = const [],
  }) async {
    if (currentTrackId.isEmpty) {
      throw Exception('Cannot prefetch next track: No current track ID');
    }

    print('Prefetching next track for: $currentTrackId');

    final recommended = await _trackRepository.getRecommendations(
      currentTrackId,
      recent: exclude,
    );

    final nextId = recommended.firstWhere(
      (id) => id != currentTrackId && !exclude.contains(id),
      orElse: () => '',
    );

    if (nextId.isNotEmpty) {
      print('Next track from station: $nextId');
      return getTrackData(nextId);
    }

    print('Station gave nothing new, falling back to random-by-artist');
    final trackData = await _trackRepository.getNextRandomSong(currentTrackId);

    final String trackId = trackData['id'] as String;
    if (trackId.isEmpty) {
      throw Exception('Invalid track ID received for next track');
    }

    final streamUrl = await _resolveStreamUrl(trackId);

    final nextTrackInfo = {
      'id': trackId,
      'title': trackData['name'] as String,
      'artist': trackData['artists'][0]['name'] as String,
      'artistId': trackData['artists'][0]['id'] as String,
      'imageUrl': trackData['album']['images'][0]['url'] as String,
      'albumName': trackData['album']['name'] as String,
      'streamUrl': streamUrl,
      'durationMs': trackData['duration_ms'] as int,
    };

    print(
      'Successfully prefetched next track: ${nextTrackInfo['title']} by ${nextTrackInfo['artist']}',
    );

    return nextTrackInfo;
  }

  /// Resolves the autoplay station for [seedTrackId] into ready-to-display
  /// queue rows (`id`, `name`, `artist`, `imageUrl`), in play order.
  ///
  /// This is the *same* list the Up-next UI shows, so seeding the queue from it
  /// guarantees the track that plays next is the one the user saw at the top.
  /// [exclude] keeps already-played tracks out of the station and the result.
  Future<List<Map<String, dynamic>>> fetchStationQueue(
    String seedTrackId, {
    List<String> exclude = const [],
    int limit = 15,
  }) async {
    final tracks = await _trackRepository.getRecommendedTracks(
      seedTrackId,
      limit: limit,
      recent: exclude,
    );

    final skip = {seedTrackId, ...exclude};
    return tracks
        .where((t) => !skip.contains(t['id'] as String? ?? ''))
        .map(
          (t) => {
            'id': t['id'] as String? ?? '',
            'name': t['name'] as String? ?? '',
            'artist': t['artist'] as String? ?? '',
            'imageUrl': t['imageUrl'] as String? ?? '',
          },
        )
        .where((t) => (t['id'] as String).isNotEmpty)
        .toList();
  }

  // Get full track data for a track ID
  Future<Map<String, dynamic>> getTrackData(String trackId) async {
    // Get track data
    final trackData = await _trackRepository.getTrack(trackId);

    // Get the stream URL
    final streamUrl = await _resolveStreamUrl(trackId);

    // Extract needed information
    final artist = trackData['artists'][0]['name'] as String;
    final artistId = trackData['artists'][0]['id'] as String;
    final title = trackData['name'] as String;
    final imageUrl = trackData['album']['images'][0]['url'] as String;
    final albumName = trackData['album']['name'] as String;
    final durationMs = trackData['duration_ms'] as int;

    // Return as a map
    return {
      'id': trackId,
      'title': title,
      'artist': artist,
      'artistId': artistId,
      'imageUrl': imageUrl,
      'albumName': albumName,
      'streamUrl': streamUrl,
      'durationMs': durationMs,
    };
  }
}
