import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/models/lyrics.dart';
import 'package:spotACrack/repositories/track_repository.dart';

/// Lyrics for a track, keyed by id so revisiting one is free and switching
/// tracks fetches its own set.
final lyricsProvider = FutureProvider.family<Lyrics, String>((ref, trackId) {
  if (trackId.isEmpty) return Future.value(const Lyrics.none(''));
  return ref.watch(trackRepositoryProvider).getLyrics(trackId);
});
