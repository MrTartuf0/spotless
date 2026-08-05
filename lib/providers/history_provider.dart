import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/services/history_service.dart';

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});

// Streams `null` on each history change so StreamProvider-based consumers
// re-read automatically. Exposed separately so widgets can listen without
// taking a dependency on HistoryService directly.
final historyChangesProvider = StreamProvider<void>((ref) {
  return ref.watch(historyServiceProvider).onChange;
});

final recentTracksProvider = FutureProvider<List<RecentTrack>>((ref) async {
  // Re-run whenever history changes.
  ref.watch(historyChangesProvider);
  return ref.watch(historyServiceProvider).recentTracks();
});

final recentAlbumsProvider = FutureProvider<List<RecentAlbum>>((ref) async {
  ref.watch(historyChangesProvider);
  return ref.watch(historyServiceProvider).recentAlbums();
});

final recentArtistsProvider = FutureProvider<List<RecentArtist>>((ref) async {
  ref.watch(historyChangesProvider);
  return ref.watch(historyServiceProvider).recentArtists();
});
