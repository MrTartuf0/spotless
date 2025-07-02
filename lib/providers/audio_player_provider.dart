// lib/providers/audio_player_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:rick_spot/repositories/track_repository.dart';
import 'package:rick_spot/services/color_extractor.dart';
import 'package:rick_spot/services/audio_service.dart';
import 'package:rick_spot/providers/searchbar_provider.dart';

// Audio Player State Model
class AudioPlayerState {
  final bool isPlaying;
  final bool isLoading;
  final Duration currentPosition;
  final Duration totalDuration;
  final String currentTrackTitle;
  final String currentTrackArtist;
  final String currentTrackImage;
  final String currentStreamUrl;
  final String currentAlbumName;
  final String currentTrackId;
  final bool isLiked;
  final bool isShuffled;
  final int repeatMode; // 0: off, 1: all, 2: one
  final Color dominantColor;
  final bool isExtractingColor;
  final String currentArtistId;

  const AudioPlayerState({
    this.isPlaying = false,
    this.isLoading = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.currentTrackTitle = '',
    this.currentTrackArtist = '',
    this.currentTrackImage = '',
    this.currentStreamUrl = '',
    this.currentAlbumName = '',
    this.currentTrackId = '',
    this.isLiked = false,
    this.isShuffled = false,
    this.repeatMode = 0,
    this.currentArtistId = '',
    this.dominantColor = const Color(0xFF7F1D1D),
    this.isExtractingColor = false,
  });

  AudioPlayerState copyWith({
    bool? isPlaying,
    bool? isLoading,
    Duration? currentPosition,
    Duration? totalDuration,
    String? currentTrackTitle,
    String? currentTrackArtist,
    String? currentTrackImage,
    String? currentStreamUrl,
    String? currentAlbumName,
    String? currentTrackId,
    String? currentArtistId,
    bool? isLiked,
    bool? isShuffled,
    int? repeatMode,
    Color? dominantColor,
    bool? isExtractingColor,
  }) {
    return AudioPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      currentTrackTitle: currentTrackTitle ?? this.currentTrackTitle,
      currentTrackArtist: currentTrackArtist ?? this.currentTrackArtist,
      currentTrackImage: currentTrackImage ?? this.currentTrackImage,
      currentStreamUrl: currentStreamUrl ?? this.currentStreamUrl,
      currentAlbumName: currentAlbumName ?? this.currentAlbumName,
      currentTrackId: currentTrackId ?? this.currentTrackId,
      currentArtistId: currentArtistId ?? this.currentArtistId,
      isLiked: isLiked ?? this.isLiked,
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
      dominantColor: dominantColor ?? this.dominantColor,
      isExtractingColor: isExtractingColor ?? this.isExtractingColor,
    );
  }

  double get progress {
    if (totalDuration.inMilliseconds > 0) {
      return currentPosition.inMilliseconds / totalDuration.inMilliseconds;
    }
    return 0.0;
  }
}

// Audio Player Notifier
class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioService _audioService = AudioService(); // This is now a singleton
  final TrackRepository _trackRepository;
  final Ref ref;

  AudioPlayerNotifier(this._trackRepository, this.ref)
    : super(const AudioPlayerState()) {
    _initializeAudioPlayer();
    // REMOVED: Don't load default track automatically
    // loadTrack(state.currentTrackId);
  }

  void _initializeAudioPlayer() {
    // Use the listener methods from our singleton
    _audioService.addPlayerStateListener((PlayerState playerState) {
      state = state.copyWith(
        isPlaying: playerState == PlayerState.playing,
        isLoading: playerState == PlayerState.playing ? false : state.isLoading,
      );
    });

    _audioService.addPositionListener((Duration position) {
      state = state.copyWith(currentPosition: position);
    });

    _audioService.addDurationListener((Duration duration) {
      state = state.copyWith(totalDuration: duration);
    });

    _audioService.addCompletionListener(() {
      // First update state to reflect the track has ended
      state = state.copyWith(isPlaying: false, currentPosition: Duration.zero);

      // Check repeat mode
      if (state.repeatMode == 2) {
        // Repeat one - play the same track again
        playStream(fromBeginning: true);
      } else if (state.repeatMode == 1 || state.isShuffled) {
        // Repeat all or shuffle - play the next track
        _playNextTrack();
      }
      // If repeat mode is 0 (off) and not shuffled, just stop (default behavior)
    });
  }

  // Updated method to play the next track using the current track ID
  Future<void> _playNextTrack() async {
    try {
      // Don't proceed if there's no current track ID
      if (state.currentTrackId.isEmpty) {
        print('Cannot play next track: No current track ID');
        return;
      }

      print(
        'Playing next track from current track ID: ${state.currentTrackId}',
      );

      // Use the current track ID to get the next random song
      final trackData = await _trackRepository.getNextRandomSong(
        state.currentTrackId,
      );

      // Extract the new track ID
      final String trackId = trackData['id'];

      if (trackId.isEmpty) {
        throw Exception('Invalid track ID received from next random song');
      }

      // Load and play the track
      loadTrack(trackId);
    } catch (e) {
      print('Error playing next track: $e');
    }
  }

  Future<void> extractDominantColor(String imageUrl) async {
    try {
      state = state.copyWith(isExtractingColor: true);

      // Force a new image instance to avoid caching issues
      final imageProvider = NetworkImage(imageUrl, scale: 1.0);

      // Add a small delay to ensure the image has time to be resolved
      await Future.delayed(Duration(milliseconds: 300));

      // Extract the color
      final Color extractedColor = await ColorExtractor.extractDominantColor(
        imageProvider,
      );

      // Update state with new color
      state = state.copyWith(
        dominantColor: extractedColor,
        isExtractingColor: false,
      );
    } catch (e) {
      print('Error extracting color: $e');
      state = state.copyWith(isExtractingColor: false);
    }
  }

  Future<void> loadTrack(String trackId) async {
    try {
      // Ensure keyboard is hidden and bottom player is visible
      if (ref.read(searchStateProvider.notifier).state.isKeyboardVisible) {
        ref.read(searchStateProvider.notifier).setKeyboardVisible(false);
      }

      // Don't proceed if trackId is empty
      if (trackId.isEmpty) return;

      // First, stop any existing playback and reset player state
      await _audioService.stop();

      // Set loading state
      state = state.copyWith(
        isLoading: true,
        currentTrackId: trackId, // Update track ID immediately
        isPlaying: false, // Reset playing state
        currentPosition: Duration.zero, // Reset position
      );

      print('Loading track: $trackId');

      // Get track data
      final trackData = await _trackRepository.getTrack(trackId);

      // Get the correct stream URL for this track
      final streamUrl = await _trackRepository.getStreamUrl(trackId);
      print('Stream URL for track $trackId: $streamUrl');

      // Extract needed information from track data
      final artist = trackData['artists'][0]['name'] as String;
      final artistId = trackData['artists'][0]['id'] as String;
      final title = trackData['name'] as String;
      final imageUrl = trackData['album']['images'][0]['url'] as String;
      final albumName = trackData['album']['name'] as String;
      final durationMs = trackData['duration_ms'] as int;

      // Update the state with the track data
      state = state.copyWith(
        currentTrackTitle: title,
        currentTrackArtist: artist,
        currentArtistId: artistId, // Store the artist ID
        currentTrackImage: imageUrl,
        currentAlbumName: albumName,
        totalDuration: Duration(milliseconds: durationMs),
        currentStreamUrl: streamUrl,
      );

      // Extract dominant color from album art
      await extractDominantColor(imageUrl);

      // Only start playing after color extraction is complete
      // Force a clean player initialization by using fromBeginning: true
      await _audioService.play(streamUrl, fromBeginning: true);

      // Update loading state
      state = state.copyWith(isLoading: false);
    } catch (e) {
      print('Error loading track: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> playStream({bool fromBeginning = true}) async {
    try {
      // Ensure keyboard is hidden and bottom player is visible
      if (ref.read(searchStateProvider.notifier).state.isKeyboardVisible) {
        ref.read(searchStateProvider.notifier).setKeyboardVisible(false);
      }

      // Don't proceed if there's no stream URL
      if (state.currentStreamUrl.isEmpty) return;

      state = state.copyWith(isLoading: true);

      // First, explicitly stop any currently playing audio
      await _audioService.stop();

      // A small delay to ensure proper cleanup
      await Future.delayed(Duration(milliseconds: 300));

      // Play using our singleton audio service
      await _audioService.play(
        state.currentStreamUrl,
        fromBeginning: fromBeginning,
      );
    } catch (e) {
      print('Error playing HLS stream: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> togglePlayPause() async {
    try {
      // Ensure keyboard is hidden and bottom player is visible
      if (ref.read(searchStateProvider.notifier).state.isKeyboardVisible) {
        ref.read(searchStateProvider.notifier).setKeyboardVisible(false);
      }

      // Don't proceed if there's no track loaded
      if (state.currentTrackId.isEmpty) return;

      if (state.isPlaying) {
        await _audioService.pause();
      } else {
        state = state.copyWith(isLoading: true);

        if (_audioService.currentState == PlayerState.stopped) {
          // Get the current position
          final currentPosition = state.currentPosition;

          // Start playback, but don't reset to beginning
          await _audioService.play(
            state.currentStreamUrl,
            fromBeginning: false,
          );

          // Ensure we seek to the right position after a small delay
          if (currentPosition > Duration.zero) {
            await Future.delayed(Duration(milliseconds: 200));
            await _audioService.seek(currentPosition);
          }
        } else {
          await _audioService.resume();
        }

        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // Method to play next track - can be called externally
  Future<void> playNextTrack() async {
    await _playNextTrack();
  }

  Future<void> seekTo(Duration position) async {
    try {
      // Update our state immediately to reflect the seek position
      state = state.copyWith(currentPosition: position);

      // Then perform the actual seek operation
      await _audioService.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  void toggleLike() {
    state = state.copyWith(isLiked: !state.isLiked);
  }

  void toggleShuffle() {
    state = state.copyWith(isShuffled: !state.isShuffled);
  }

  void toggleRepeat() {
    state = state.copyWith(repeatMode: (state.repeatMode + 1) % 3);
  }

  String formatTime(Duration duration) {
    int mins = duration.inMinutes;
    int secs = duration.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Stop any playing audio when disposing
    _audioService.stop();
    super.dispose();
  }
}

// Provider
final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      final trackRepository = ref.watch(trackRepositoryProvider);
      return AudioPlayerNotifier(trackRepository, ref);
    });

// Current track ID provider - starting with empty string
final currentTrackIdProvider = StateProvider<String>((ref) {
  return ''; // Empty string means no track loaded by default
});
