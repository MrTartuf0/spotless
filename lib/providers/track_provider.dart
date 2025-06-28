// lib/providers/track_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rick_spot/models/track_model.dart';
import 'package:rick_spot/repositories/track_repository.dart';

final currentTrackProvider = StateProvider<String>((ref) {
  // Default track ID
  return '3d9DChrdc6BOeFsbrZ3Is0'; // Under the Bridge
});

// Updated to match the repository's return type
final trackDataProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  trackId,
) async {
  final repository = ref.watch(trackRepositoryProvider);
  return repository.getTrack(trackId);
});

// Helper provider to convert raw track data to a formatted model if needed
final formattedTrackProvider = FutureProvider.family<TrackModel, String>((
  ref,
  trackId,
) async {
  final trackData = await ref.watch(trackDataProvider(trackId).future);

  // Convert the map to a TrackModel
  return TrackModel(
    id: trackData['id'] as String,
    name: trackData['name'] as String,
    artists:
        (trackData['artists'] as List)
            .map(
              (artist) => Artist(
                id: artist['id'] as String,
                name: artist['name'] as String,
              ),
            )
            .toList(),
    album: Album(
      id: trackData['album']['id'] as String,
      name: trackData['album']['name'] as String,
      images:
          (trackData['album']['images'] as List)
              .map(
                (image) => Image(
                  url: image['url'] as String,
                  width: image['width'] as int,
                  height: image['height'] as int,
                ),
              )
              .toList(),
    ),
    durationMs: trackData['duration_ms'] as int,
  );
});
