// lib/providers/audio_player/track_queue_service.dart
import 'package:rick_spot/repositories/track_repository.dart';

class TrackQueueService {
  final TrackRepository _trackRepository;

  TrackQueueService(this._trackRepository);

  // Fetch next track based on current track ID
  Future<Map<String, dynamic>> fetchNextTrack(String currentTrackId) async {
    if (currentTrackId.isEmpty) {
      throw Exception('Cannot prefetch next track: No current track ID');
    }

    print('Prefetching next track for: $currentTrackId');

    // Get next random track data
    final trackData = await _trackRepository.getNextRandomSong(currentTrackId);

    // Extract track ID
    final String trackId = trackData['id'] as String;

    if (trackId.isEmpty) {
      throw Exception('Invalid track ID received for next track');
    }

    // Get the stream URL
    final streamUrl = await _trackRepository.getStreamUrl(trackId);

    // Create track info map
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

  // Get full track data for a track ID
  Future<Map<String, dynamic>> getTrackData(String trackId) async {
    // Get track data
    final trackData = await _trackRepository.getTrack(trackId);

    // Get the stream URL
    final streamUrl = await _trackRepository.getStreamUrl(trackId);

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
