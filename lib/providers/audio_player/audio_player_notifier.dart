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
import 'package:spotACrack/services/history_service.dart';
import 'package:spotACrack/providers/searchbar_provider.dart';

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final TrackRepository _trackRepository;
  final Ref _ref;

  // Services
  late final TrackPlaybackService _playbackService;
  late final TrackQueueService _queueService;
  late final TrackCompletionService _completionService;

  // State management flags
  bool _isHandlingCompletion = false;
  // Guards against a double-tap on next/prev starting two loads at once, which
  // leaves the history index and the player disagreeing about what is playing.
  bool _isSwitchingTrack = false;
  Completer<void>? _pendingCompletion;
  DateTime _lastCompletionTime = DateTime.now();

  AudioPlayerNotifier(this._trackRepository, this._ref)
    : super(const AudioPlayerState()) {
    _initializeServices();
  }

  void _initializeServices() {
    // Initialize the audio playback service
    _playbackService = TrackPlaybackService(
      audioService: AudioService(),
      onPlayerStateChanged: _handlePlayerStateChanged,
      onPositionChanged: _handlePositionChanged,
      onTrackCompleted: _handleTrackCompleted,
    );

    // Initialize the queue service
    _queueService = TrackQueueService(_trackRepository);

    // Initialize the completion service with progress checker function.
    // Route every completion trigger (watchdog, end-of-track timer, etc.)
    // through _safeHandleCompletion so the debounce is the single gate.
    _completionService = TrackCompletionService(
      onTrackComplete: _safeHandleCompletion,
      onPrefetchNeeded: _prefetchNextTrack,
      progressChecker: (ignored) => state.progress,
    );
  }

  // Event handlers for playback events
  void _handlePlayerStateChanged(PlayerState playerState) {
    print("Player state changed to: $playerState");

    state = state.copyWith(
      isPlaying: playerState == PlayerState.playing,
      isLoading: playerState == PlayerState.playing ? false : state.isLoading,
    );

    // Handle completion only when the player explicitly reports it
    if (playerState == PlayerState.completed) {
      print("⭐ PLAYER STATE COMPLETED DETECTED ⭐");
      _safeHandleCompletion();
    }
  }

  void _handlePositionChanged(Duration position) {
    // Update state position
    state = state.copyWith(currentPosition: position);

    final progress = state.progress;

    // Prefetch logic
    if (_completionService.shouldPrefetch(progress) &&
        _shouldPrefetchNextTrack() &&
        !state.isLoading) {
      _prefetchNextTrack();
    }

    // Completion logic - only handle through position changes
    if (_completionService.shouldForceCompletion(progress)) {
      print(
        "Position at ${(progress * 100).toStringAsFixed(1)}% of track, forcing completion",
      );
      _safeHandleCompletion();
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

  void _handleTrackCompleted() {
    print("⭐ COMPLETION LISTENER TRIGGERED ⭐");
    _safeHandleCompletion();
  }

  // Safe completion handling with debouncing
  Future<void> _safeHandleCompletion() async {
    // Prevent multiple completion handlers from running simultaneously
    if (_isHandlingCompletion) {
      print("Completion already in progress, queuing request");
      // If we already have a pending completion, wait for it
      if (_pendingCompletion != null) {
        await _pendingCompletion!.future;
      }
      return;
    }

    // Debounce completion events
    final now = DateTime.now();
    if (now.difference(_lastCompletionTime) < Duration(milliseconds: 500)) {
      print("Completion debounced");
      return;
    }

    _isHandlingCompletion = true;
    _lastCompletionTime = now;
    _pendingCompletion = Completer<void>();

    try {
      await _handleTrackCompletion();
      _pendingCompletion!.complete();
    } catch (e) {
      _pendingCompletion!.completeError(e);
      print("Error in completion handling: $e");
    } finally {
      _isHandlingCompletion = false;
      _pendingCompletion = null;
    }
  }

  // Core functionality methods
  Future<void> _handleTrackCompletion() async {
    print("Handling track completion");

    // Cancel any pending timers
    _completionService.cancelTrackEndTimer();
    _completionService.cancelWatchdogTimer();

    // Check repeat mode
    if (state.repeatMode == 2) {
      // Repeat one - play the same track again
      print("Repeat One mode: replaying current track");
      await _replayCurrentTrack();
    } else {
      // Play next track
      print("Playing next track after completion");
      await _playNextTrackAfterCompletion();
    }
  }

  Future<void> _replayCurrentTrack() async {
    // Stop current playback
    await _playbackService.stop();

    // Reset position and play again
    state = state.copyWith(
      currentPosition: Duration.zero,
      isTrackEnding: false,
    );

    await playStream(fromBeginning: true);
  }

  Future<void> _playNextTrackAfterCompletion() async {
    // Update state to reflect completion
    state = state.copyWith(
      currentPosition: state.totalDuration,
      isPlaying: false,
      isTrackEnding: false,
    );

    // Stop current playback
    await _playbackService.stop();

    // Play next track
    await _playNextTrack();
  }

  bool _shouldPrefetchNextTrack() {
    final nextIndex = state.index + 1;

    // Check if we already have the next track in history
    if (nextIndex < state.trackIdHistory.length &&
        state.trackIdHistory[nextIndex].isNotEmpty) {
      return false;
    }

    // Don't prefetch if we're at the end of available tracks
    if (state.hasNextTrack == false) {
      return false;
    }

    return true;
  }

  Future<void> _prefetchNextTrack() async {
    try {
      // Don't proceed if there's no current track ID
      if (state.currentTrackId.isEmpty) {
        return;
      }

      print('Fetching next track to add to history');

      // Check if we already have a next track
      final nextIndex = state.index + 1;
      if (nextIndex < state.trackIdHistory.length &&
          state.trackIdHistory[nextIndex].isNotEmpty) {
        print('Next track already exists in history');
        return;
      }

      if (state.isNextTrackLoading) {
        print('Next track is already loading');
        return;
      }

      state = state.copyWith(isNextTrackLoading: true);

      final nextTrackInfo = await _queueService.fetchNextTrack(
        state.currentTrackId,
        exclude: state.trackIdHistory,
      );

      if (nextTrackInfo['id'] == null || nextTrackInfo['id'].isEmpty) {
        print('No next track available');
        state = state.copyWith(hasNextTrack: false);
        return;
      }

      final newTrackId = nextTrackInfo['id'] as String;
      final updatedHistory = List<String>.from(state.trackIdHistory);
      if (nextIndex >= updatedHistory.length) {
        updatedHistory.add(newTrackId);
      } else {
        updatedHistory[nextIndex] = newTrackId;
      }

      state = state.copyWith(trackIdHistory: updatedHistory);
      print('Queued track $newTrackId at position $nextIndex');
    } catch (e) {
      print('Error fetching next track: $e');
      state = state.copyWith(hasNextTrack: false);
    } finally {
      state = state.copyWith(isNextTrackLoading: false);
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

      // Check if we have the next track in history
      final nextIndex = state.index + 1;
      if (nextIndex < state.trackIdHistory.length &&
          state.trackIdHistory[nextIndex].isNotEmpty) {
        print(
          'Playing next track from history: ${state.trackIdHistory[nextIndex]}',
        );
        await _loadTrack(
          state.trackIdHistory[nextIndex],
          historyIndex: nextIndex,
        );
        return;
      }

      // If no track in history, fetch a new one
      print('Fetching next track as none found in history');
      final nextTrackInfo = await _queueService.fetchNextTrack(
        state.currentTrackId,
        exclude: state.trackIdHistory,
      );

      if (nextTrackInfo['id'] == null || nextTrackInfo['id'].isEmpty) {
        print('No next track available');
        state = state.copyWith(isLoading: false, hasNextTrack: false);
        return;
      }

      // Load and play the track
      await _loadTrack(nextTrackInfo['id']);
    } catch (e) {
      print('Error playing next track: $e');
      state = state.copyWith(isLoading: false, hasNextTrack: false);
    }
  }

  // Public API methods
  Future<void> extractDominantColor(String imageUrl) async {
    try {
      state = state.copyWith(isExtractingColor: true);

      // Force a new image instance to avoid caching issues
      final imageProvider = NetworkImage(imageUrl, scale: 1.0);

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
    await _loadTrack(trackId, addToHistory: addToHistory);
  }

  /// Loads and plays [trackId].
  ///
  /// [historyIndex] moves the pointer to an entry that is already in the
  /// history, for prev/next navigation. Without it the pointer would stay put
  /// and the track would be written over the slot the listener is currently on,
  /// which makes every later "next" replay the same song.
  Future<void> _loadTrack(
    String trackId, {
    bool addToHistory = true,
    int? historyIndex,
  }) async {
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

      // Determine the new index and history
      int newIndex = state.index;
      List<String> updatedTrackIdHistory = List.from(state.trackIdHistory);

      if (historyIndex != null) {
        // Navigating within history: move the pointer, leave the list alone.
        newIndex = historyIndex;
        if (newIndex < updatedTrackIdHistory.length) {
          updatedTrackIdHistory[newIndex] = trackId;
        } else {
          updatedTrackIdHistory.add(trackId);
        }
      } else if (addToHistory) {
        // If we're adding to history, increment index and add the track
        newIndex = state.index + 1;

        // Ensure history has enough slots
        if (newIndex >= updatedTrackIdHistory.length) {
          updatedTrackIdHistory.add(trackId);
        } else {
          updatedTrackIdHistory[newIndex] = trackId;
          // If we're overwriting history, remove any future tracks
          if (newIndex < updatedTrackIdHistory.length - 1) {
            updatedTrackIdHistory = updatedTrackIdHistory.sublist(
              0,
              newIndex + 1,
            );
          }
        }
      } else {
        // If not adding to history, just update the current track
        if (newIndex < updatedTrackIdHistory.length) {
          updatedTrackIdHistory[newIndex] = trackId;
        } else {
          updatedTrackIdHistory.add(trackId);
        }
      }

      state = state.copyWith(
        isLoading: true,
        currentTrackId: trackId,
        isPlaying: false,
        currentPosition: Duration.zero,
        isTrackEnding: false,
        trackIdHistory: updatedTrackIdHistory,
        index: newIndex,
        hasNextTrack: true, // Reset until we know otherwise
      );

      final trackInfo = await _queueService.getTrackData(trackId);

      state = state.copyWith(
        currentTrackTitle: trackInfo['title'],
        currentTrackArtist: trackInfo['artist'],
        currentArtistId: trackInfo['artistId'],
        currentTrackImage: trackInfo['imageUrl'],
        currentAlbumName: trackInfo['albumName'],
        totalDuration: Duration(milliseconds: trackInfo['durationMs']),
        currentStreamUrl: trackInfo['streamUrl'],
      );

      // Fire-and-forget: record in local history. Failures here must never
      // break playback, so errors are swallowed.
      unawaited(
        HistoryService().recordTrack(
          id: trackId,
          title: trackInfo['title'] as String,
          artist: trackInfo['artist'] as String,
          artistId: trackInfo['artistId'] as String,
          imageUrl: trackInfo['imageUrl'] as String,
        ).catchError((e) {
          print('Failed to record track in history: $e');
        }),
      );

      // Same for the artist, which is what fills the artists shelf on Home
      // and the Artists filter in the library.
      final artistId = trackInfo['artistId'] as String;
      if (artistId.isNotEmpty) {
        unawaited(
          HistoryService().recordArtist(
            id: artistId,
            name: trackInfo['artist'] as String,
          ).catchError((e) {
            print('Failed to record artist in history: $e');
          }),
        );
      }

      print("Current index is: ${state.index}");

      // Kick the artwork colour off in the background; the players animate to
      // it when it lands, so playback does not need to wait for it.
      unawaited(extractDominantColor(trackInfo['imageUrl']));

      await _playbackService.play(trackInfo['streamUrl'], fromBeginning: true);

      // Update loading state
      state = state.copyWith(isLoading: false);

      // Line up the next track once playback has settled.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_shouldPrefetchNextTrack()) {
          _prefetchNextTrack();
        }
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
        _completionService.cancelWatchdogTimer();
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
    if (state.currentTrackId.isEmpty) {
      print('Cannot play next track: No current track ID');
      return;
    }

    if (_isSwitchingTrack) {
      print('Already switching track, ignoring');
      return;
    }
    _isSwitchingTrack = true;

    try {
      if (state.index + 1 < state.trackIdHistory.length &&
          state.trackIdHistory[state.index + 1].isNotEmpty) {
        final nextIndex = state.index + 1;
        final nextTrackId = state.trackIdHistory[nextIndex];
        print('Playing next track from history: $nextTrackId');
        await _loadTrack(nextTrackId, historyIndex: nextIndex);
        return;
      }

      print('Fetching next track as none found in history');
      await _playNextTrack();
    } finally {
      _isSwitchingTrack = false;
    }
  }

  Future<void> playPreviousTrack() async {
    if (state.index <= 0) return;

    if (_isSwitchingTrack) {
      print('Already switching track, ignoring');
      return;
    }
    _isSwitchingTrack = true;

    try {
      final previousIndex = state.index - 1;
      final previousTrackId = state.trackIdHistory[previousIndex];

      print(
        'Playing previous track from history: $previousTrackId index $previousIndex',
      );

      await _loadTrack(previousTrackId, historyIndex: previousIndex);
    } finally {
      _isSwitchingTrack = false;
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      _completionService.cancelTrackEndTimer();
      _completionService.cancelWatchdogTimer();
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

  /// Sets output level, 0..1. The service keeps the value and reapplies it
  /// after the reset that every new URL triggers, so this survives track
  /// changes.
  Future<void> setVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    await _playbackService.setVolume(clamped);
    state = state.copyWith(
      volume: clamped,
      // Dragging the slider up is also how you unmute, so remember the new
      // level as the one to come back to.
      volumeBeforeMute: clamped > 0 ? clamped : state.volumeBeforeMute,
    );
  }

  Future<void> toggleMute() async {
    if (state.volume > 0) {
      final previous = state.volume;
      await _playbackService.setVolume(0);
      state = state.copyWith(volume: 0, volumeBeforeMute: previous);
    } else {
      final restored = state.volumeBeforeMute > 0 ? state.volumeBeforeMute : 1.0;
      await _playbackService.setVolume(restored);
      state = state.copyWith(volume: restored);
    }
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
