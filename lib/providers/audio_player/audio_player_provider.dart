// lib/providers/audio_player/audio_player_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rick_spot/providers/audio_player/audio_player_state.dart';
import 'package:rick_spot/providers/audio_player/audio_player_notifier.dart';
import 'package:rick_spot/repositories/track_repository.dart';

// Main provider
final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      final trackRepository = ref.watch(trackRepositoryProvider);
      return AudioPlayerNotifier(trackRepository, ref);
    });

// Current track ID provider - starting with empty string
final currentTrackIdProvider = StateProvider<String>((ref) {
  return ''; // Empty string means no track loaded by default
});
