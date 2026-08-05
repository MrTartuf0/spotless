import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/repositories/track_repository.dart';

/// Spotify's station for a seed track, used to fill the "More like ..." row.
///
/// Keyed by seed id so switching tracks fetches its own station and the old
/// one stays cached.
final recommendedTracksProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      seedTrackId,
    ) async {
      if (seedTrackId.isEmpty) return const [];
      return ref
          .watch(trackRepositoryProvider)
          .getRecommendedTracks(seedTrackId, limit: 10);
    });
