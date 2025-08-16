// lib/providers/audio_player/audio_player_notifier.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:spotACrack/providers/audio_player/audio_player_state.dart';
import 'package:spotACrack/providers/audio_player/track_completion_service.dart';
import 'package:spotACrack/providers/audio_player/track_queue_service.dart';
import 'package:spotACrack/providers/audio_player/track_playback_service.dart';
import 'package:spotACrack/repositories/track_repository.dart';
import 'package:spotACrack/services/color_extractor.dart';
import 'package:spotACrack/services/audio_service.dart';
import 'package:spotACrack/providers/searchbar_provider.dart';

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final TrackRepository _trackRepository;
  final Ref _ref;

  // Services
  late final TrackPlaybackService _playbackService;
  late final TrackQueueService _queueService;
  late final TrackCompletionService _completionService;

  AudioPlayerNotifier(this._trackRepository, this._ref)
    : super(const AudioPlayerState()) {
    _initializeServices();
    _initializeListeners();
  }

  void _initializeServices() {
    // Initialize the audio playback service
    _playbackService = TrackPlaybackService(
      audioService: AudioService(),
      onPlayerStateChanged: _handlePlayerStateChanged,
      onPositionChanged: _handlePositionChanged,
      onDurationChanged: _handleDurationChanged,
      onTrackCompleted: _handleTrackCompleted,
    );

    // Initialize the queue service
    _queueService = TrackQueueService(_trackRepository);

    // Initialize the completion service with progress checker function
    _completionService = TrackCompletionService(
      onTrackComplete: _handleTrackCompletion,
      onPrefetchNeeded: _prefetchNextTrack,
      progressChecker:
          (ignored) => state.progress, // Pass current progress from state
    );
  }

  // And add an explicit _startNextTrack() method to handle the transition
  Future<void> _startNextTrack() async {
    // Always stop current playback immediately to prevent conflicts
    await _playbackService.stop();

    // Choose the appropriate method based on what's available
    print("🚀 Finding and playing next track...");
    await _playNextTrack();
  }

  void _initializeListeners() {
    // Additional initialization code can go here
  }

  // Event handlers for playback events
  void _handlePlayerStateChanged(PlayerState playerState) {
    print("Player state changed to: $playerState");

    // Check if player just completed
    if (playerState == PlayerState.completed) {
      print("⭐ PLAYER STATE COMPLETED DETECTED ⭐");
      Future.microtask(_handleTrackCompletion);
    }

    state = state.copyWith(
      isPlaying: playerState == PlayerState.playing,
      isLoading: playerState == PlayerState.playing ? false : state.isLoading,
    );

    // If we were playing and now we're not, check if we need to handle completion
    if ((playerState == PlayerState.paused ||
            playerState == PlayerState.stopped) &&
        state.currentPosition.inMilliseconds > 0) {
      final progress = state.progress;
      if (progress > 0.97) {
        print(
          "Player paused/stopped near end (${(progress * 100).toStringAsFixed(1)}%), checking if completion needed",
        );
        _completionService.checkTrackCompletion(progress);
      }
    }
  }

  void _handlePositionChanged(Duration position) {
    // Update state position
    state = state.copyWith(currentPosition: position);

    final progress = state.progress;

    // Check if we should prefetch the next track
    if (_completionService.shouldPrefetch(progress) &&
        state.nextTrackId.isEmpty &&
        !state.isNextTrackLoading) {
      _prefetchNextTrack();
    }

    // Check if we should force completion
    if (_completionService.shouldForceCompletion(progress)) {
      print(
        "Position at ${(progress * 100).toStringAsFixed(1)}% of track, forcing next track",
      );
      _completionService.checkTrackCompletion(progress);
    }
    // Check for normal completion
    else if (progress > 0.98 && !_completionService.isCompletionHandled) {
      print(
        "Position at ${(progress * 100).toStringAsFixed(1)}% of track, checking completion",
      );
      _completionService.checkTrackCompletion(progress);
    }

    // Schedule end timer if needed
    if (_completionService.isNearEnd(progress) && !state.isTrackEnding) {
      state = state.copyWith(isTrackEnding: true);
      _completionService.scheduleEndOfTrackTimer(
        progress,
        state.totalDuration,
        position,
      );
    }
  }

  void _handleDurationChanged(Duration duration) {
    state = state.copyWith(totalDuration: duration);
    print("Track duration set: ${_playbackService.formatTime(duration)}");

    // Set up watchdog timer when we know the duration
    _completionService.setupWatchdogTimer(duration, state.isPlaying);
  }

  void _handleTrackCompleted() {
    print("⭐ COMPLETION LISTENER TRIGGERED ⭐");
    _handleTrackCompletion();
  }

  // Core functionality methods
  Future<void> _handleTrackCompletion() async {
    // Prevent multiple handlers and reentrance
    if (_completionService.isHandlingTrackEnd ||
        _completionService.isCompletionHandled)
      return;

    _completionService.setHandlingTrackEnd(true);
    _completionService.setCompletionHandled(true);

    try {
      print("Handling track completion");

      // Cancel any pending timers
      _completionService.cancelTrackEndTimer();
      _completionService.cancelWatchdogTimer();

      // Check repeat mode
      if (state.repeatMode == 2) {
        // Repeat one - play the same track again
        print("Repeat One mode: replaying current track");
        await playStream(fromBeginning: true);
      } else {
        // Always play next track, regardless of repeat mode
        print("Playing next track after completion");

        // Immediate state update to prevent further completion events
        state = state.copyWith(
          currentPosition: state.totalDuration, // Force position to end
          isPlaying: false, // Mark as not playing
        );

        // Stop the current track immediately to prevent more events
        await _playbackService.stop();

        // Use a Future.microtask to ensure this executes after current call stack
        Future.microtask(() async {
          // Call with slight delay to ensure clean transition
          await Future.delayed(Duration(milliseconds: 300));
          await _startNextTrack();
        });
      }
    } catch (e) {
      print("Error handling track completion: $e");
      // If there was an error, try to recover by playing next track directly
      try {
        await Future.delayed(Duration(milliseconds: 500));
        await _playNextTrack();
      } catch (_) {
        // Last resort recovery attempt
      }
    } finally {
      // Small delay before clearing handling flag to prevent race conditions
      Future.delayed(Duration(milliseconds: 500), () {
        _completionService.setHandlingTrackEnd(false);
      });
    }
  }

  Future<void> _prefetchNextTrack() async {
    try {
      // Don't proceed if there's no current track ID
      if (state.currentTrackId.isEmpty) {
        return;
      }

      print('Fetching next track to add to history');

      // Fetch the next track
      final nextTrackInfo = await _queueService.fetchNextTrack(
        state.currentTrackId,
      );

      if (!state.trackIdHistory.contains(nextTrackInfo['id'])) {
        // Add to the END of the history array
        state = state.copyWith(
          trackIdHistory: [...state.trackIdHistory, nextTrackInfo['id']],
        );
        print('Added track ${nextTrackInfo['id']} to history');
      } else {
        print('Track ${nextTrackInfo['id']} already exists in history');
      }
    } catch (e) {
      print('Error fetching next track: $e');
    }
  }

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
      state = state.copyWith(isLoading: true);

      // Use the queue service to get the next track
      final nextTrackInfo = await _queueService.fetchNextTrack(
        state.currentTrackId,
      );

      // Load and play the track
      loadTrack(nextTrackInfo['id']);
    } catch (e) {
      print('Error playing next track: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // Public API methods
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

  Future<void> loadTrack(String trackId, {bool addToHistory = true}) async {
    try {
      // Ensure keyboard is hidden and bottom player is visible
      if (_ref.read(searchStateProvider.notifier).state.isKeyboardVisible) {
        _ref.read(searchStateProvider.notifier).setKeyboardVisible(false);
      }

      // Don't proceed if trackId is empty
      if (trackId.isEmpty) return;

      // First, stop any existing playback and reset player state
      await _playbackService.stop();
      _completionService.cancelTrackEndTimer();
      _completionService.cancelWatchdogTimer();
      _completionService.setCompletionHandled(false);

      // Create a new track ID history, adding the trackId only if addToHistory is true
      final updatedTrackIdHistory =
          addToHistory
              ? [...state.trackIdHistory, trackId]
              : state.trackIdHistory;

      state = state.copyWith(
        isLoading: true,
        currentTrackId: trackId, // Update track ID immediately
        isPlaying: false, // Reset playing state
        currentPosition: Duration.zero, // Reset position
        isTrackEnding: false, // Reset end flag
        nextTrackId: '', // Clear next track data
        nextTrackTitle: '',
        nextTrackArtist: '',
        nextTrackImage: '',
        nextStreamUrl: '',
        trackIdHistory: updatedTrackIdHistory, // Update the track ID history
      );

      print('Loading track: $trackId');
      print(updatedTrackIdHistory);

      // Get track data using the queue service
      final trackInfo = await _queueService.getTrackData(trackId);

      // Update the state with the track data
      state = state.copyWith(
        currentTrackTitle: trackInfo['title'],
        currentTrackArtist: trackInfo['artist'],
        currentArtistId: trackInfo['artistId'],
        currentTrackImage: trackInfo['imageUrl'],
        currentAlbumName: trackInfo['albumName'],
        totalDuration: Duration(milliseconds: trackInfo['durationMs']),
        currentStreamUrl: trackInfo['streamUrl'],
      );

      // Extract dominant color from album art
      await extractDominantColor(trackInfo['imageUrl']);

      // Only start playing after color extraction is complete
      await _playbackService.play(trackInfo['streamUrl'], fromBeginning: true);

      // Update loading state
      state = state.copyWith(isLoading: false);

      // Prefetch the next track after a short delay
      Future.delayed(Duration(seconds: 2), () {
        _prefetchNextTrack();
      });
    } catch (e) {
      print('Error loading track: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> playStream({bool fromBeginning = true}) async {
    try {
      // Cancel any existing watchdog
      _completionService.cancelWatchdogTimer();

      // Ensure keyboard is hidden and bottom player is visible
      if (_ref.read(searchStateProvider.notifier).state.isKeyboardVisible) {
        _ref.read(searchStateProvider.notifier).setKeyboardVisible(false);
      }

      // Don't proceed if there's no stream URL
      if (state.currentStreamUrl.isEmpty) return;

      state = state.copyWith(isLoading: true);

      // First, explicitly stop any currently playing audio
      await _playbackService.stop();
      _completionService.cancelTrackEndTimer();
      _completionService.setCompletionHandled(false);

      // A small delay to ensure proper cleanup
      await Future.delayed(Duration(milliseconds: 300));

      // Play using our playback service
      await _playbackService.play(
        state.currentStreamUrl,
        fromBeginning: fromBeginning,
      );

      // Update state
      state = state.copyWith(isLoading: false);
    } catch (e) {
      print('Error playing HLS stream: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> togglePlayPause() async {
    try {
      // Ensure keyboard is hidden and bottom player is visible
      if (_ref.read(searchStateProvider.notifier).state.isKeyboardVisible) {
        _ref.read(searchStateProvider.notifier).setKeyboardVisible(false);
      }

      // Don't proceed if there's no track loaded
      if (state.currentTrackId.isEmpty) return;

      if (state.isPlaying) {
        await _playbackService.pause();
        _completionService
            .cancelWatchdogTimer(); // Cancel watchdog when pausing
      } else {
        state = state.copyWith(isLoading: true);

        if (_playbackService.currentState == PlayerState.stopped) {
          // Get the current position
          final currentPosition = state.currentPosition;

          // Start playback, but don't reset to beginning
          await _playbackService.play(
            state.currentStreamUrl,
            fromBeginning: false,
          );

          // Ensure we seek to the right position after a small delay
          if (currentPosition > Duration.zero) {
            await Future.delayed(Duration(milliseconds: 200));
            await _playbackService.seek(currentPosition);
          }
        } else {
          await _playbackService.resume();
        }

        // Reset the watchdog timer when resuming
        _completionService.setupWatchdogTimer(state.totalDuration, true);

        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> playNextTrack() async {
    // Check if there's a track after the current one in trackIdHistory
    if (state.currentTrackId.isNotEmpty && state.trackIdHistory.isNotEmpty) {
      final currentIndex = state.trackIdHistory.indexOf(state.currentTrackId);
      if (currentIndex != -1 &&
          currentIndex < state.trackIdHistory.length - 1) {
        // There's a track after the current one in history
        final nextTrackId = state.trackIdHistory[currentIndex + 1];
        print('Playing next track from history: $nextTrackId');
        await loadTrack(nextTrackId);
        return;
      }
    }

    // If no track in history, fetch a new one
    if (!state.isNextTrackLoading) {
      print('Fetching next track as none found in history');
      await _playNextTrack();
    } else {
      print('Next track is still loading, please wait...');
    }
  }

  Future<void> playPreviousTrack() async {
    // Check if there's a track before the current one in trackIdHistory
    if (state.currentTrackId.isNotEmpty && state.trackIdHistory.isNotEmpty) {
      final currentIndex = state.trackIdHistory.indexOf(state.currentTrackId);
      if (currentIndex > 0) {
        // There’s a track before the current one in history
        final previousTrackId = state.trackIdHistory[currentIndex - 1];
        print('Playing previous track from history: $previousTrackId');
        await loadTrack(previousTrackId, addToHistory: false);
        return;
      }
    }

    // No previous track found in history
    print('No previous track available in history');
  }

  Future<void> seekTo(Duration position) async {
    try {
      _completionService
          .cancelTrackEndTimer(); // Cancel any end timer when manually seeking
      _completionService.cancelWatchdogTimer(); // Cancel watchdog when seeking
      _completionService.setCompletionHandled(false);

      // Update our state immediately to reflect the seek position
      final isNearEnd =
          position.inMilliseconds >
          state.totalDuration.inMilliseconds *
              TrackCompletionService.nearEndThreshold;

      state = state.copyWith(
        currentPosition: position,
        isTrackEnding: isNearEnd,
      );

      // Then perform the actual seek operation
      await _playbackService.seek(position);

      // If we're near the end after seeking, handle it
      if (isNearEnd) {
        _completionService.scheduleEndOfTrackTimer(
          state.progress,
          state.totalDuration,
          position,
        );
      }

      // Reset the watchdog timer after seeking
      _completionService.setupWatchdogTimer(
        state.totalDuration,
        state.isPlaying,
      );
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
    return _playbackService.formatTime(duration);
  }

  @override
  void dispose() {
    // Stop any playing audio when disposing
    _playbackService.stop();
    _completionService.dispose();
    super.dispose();
  }
}
