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
import 'package:spotACrack/services/media_session_service.dart';
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
  // Serialises radio-queue fetches so the seed-on-load and the prefetch-on-
  // position don't both hit the station at once.
  bool _queueBusy = false;
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

    _initializeMediaSession();
  }

  // ---------------------------------------------------------------------------
  // OS media session (lock screen, Control Center, CarPlay, Android Auto)
  //
  // Remote buttons come in through the callbacks below and go through exactly
  // the same methods the in-app controls use, so there is only one code path
  // per action. State goes back out through a single StateNotifier listener.
  // ---------------------------------------------------------------------------

  // What the session was last told, so a position tick every ~200ms doesn't
  // turn into a platform channel call every ~200ms.
  String _sessionTrackId = '';
  Duration _sessionDuration = Duration.zero;
  bool? _sessionPlaying;
  bool? _sessionLoading;
  Duration _sessionPosition = Duration.zero;

  void _initializeMediaSession() {
    if (!MediaSession.isSupported) return;

    MediaSession.instance.attach(
      // The remote sends explicit play and pause, never a toggle, so these
      // check the current state before reusing togglePlayPause.
      onPlay: () {
        if (!state.isPlaying) togglePlayPause();
      },
      onPause: () {
        if (state.isPlaying) togglePlayPause();
      },
      onNext: playNextTrack,
      onPrevious: playPreviousTrack,
      onStop: () => _playbackService.stop(),
      onSeek: seekTo,
    );

    addListener(_syncMediaSession, fireImmediately: false);
  }

  void _syncMediaSession(AudioPlayerState current) {
    if (!MediaSession.isSupported) return;

    if (current.currentTrackId.isNotEmpty &&
        (current.currentTrackId != _sessionTrackId ||
            current.totalDuration != _sessionDuration)) {
      _sessionTrackId = current.currentTrackId;
      _sessionDuration = current.totalDuration;

      MediaSession.instance.setItem(
        id: current.currentTrackId,
        title: current.currentTrackTitle,
        artist: current.currentTrackArtist,
        album: current.currentAlbumName,
        artworkUrl: current.currentTrackImage,
        duration: current.totalDuration,
      );
    }

    // The OS extrapolates the scrubber from the last position it was given,
    // so this only needs to publish on transitions — plus an occasional
    // correction for drift.
    final transitioned =
        current.isPlaying != _sessionPlaying ||
        current.isLoading != _sessionLoading;
    final drifted =
        (current.currentPosition - _sessionPosition).abs().inSeconds >= 5;
    if (!transitioned && !drifted) return;

    _sessionPlaying = current.isPlaying;
    _sessionLoading = current.isLoading;
    _sessionPosition = current.currentPosition;

    MediaSession.instance.setPlaybackState(
      playing: current.isPlaying,
      loading: current.isLoading,
      position: current.currentPosition,
      hasPrevious: current.index > 0,
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

    // Repeat-one replays the same track; everything else advances the queue.
    if (state.repeatMode == 2) {
      print("Repeat One mode: replaying current track");
      await _replayCurrentTrack();
      return;
    }

    state = state.copyWith(
      currentPosition: state.totalDuration,
      isPlaying: false,
      isTrackEnding: false,
    );
    await _playbackService.stop();
    await _advance();
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

  /// Moves to the next track. This is the one place that decides what plays
  /// next, so the button, the completion handler and the queue can never
  /// disagree about it.
  ///
  /// Order of preference:
  ///  1. A track already ahead in the visited history (you pressed *previous*
  ///     earlier and are now walking forward again).
  ///  2. The head of the explicit [AudioPlayerState.queue] — the album
  ///     remainder, or the radio snapshot the Up-next list is showing.
  ///  3. Repeat-all: refill the queue from the album and start it over.
  ///  4. The open-ended station as a last resort (queue not yet seeded, or an
  ///     album finished with repeat off — autoplay carries on like Spotify).
  Future<void> _advance() async {
    if (state.currentTrackId.isEmpty) return;
    state = state.copyWith(isLoading: true);

    final nextIndex = state.index + 1;
    if (nextIndex < state.trackIdHistory.length &&
        state.trackIdHistory[nextIndex].isNotEmpty) {
      print('Advancing through visited history to index $nextIndex');
      await _loadTrack(
        state.trackIdHistory[nextIndex],
        historyIndex: nextIndex,
      );
      return;
    }

    // Repeat-all wrap: the album drained, so queue it again from the top.
    if (state.queue.isEmpty &&
        state.repeatMode == 1 &&
        state.contextTracks.isNotEmpty) {
      print('Repeat All: wrapping to the start of the context');
      state = state.copyWith(queue: List.of(state.contextTracks));
    }

    if (state.queue.isNotEmpty) {
      final next = Map<String, dynamic>.of(state.queue.first);
      state = state.copyWith(queue: state.queue.sublist(1));
      final id = next['id'] as String? ?? '';
      if (id.isNotEmpty) {
        print('Advancing to queued track $id');
        await _loadTrack(id, resetContext: false);
        // Keep radio queues from running dry; album queues are left fixed.
        unawaited(_ensureQueueReady());
        return;
      }
    }

    print('Queue empty; falling back to the station');
    await _playFromStation();
  }

  /// Last-resort next track: one song from the autoplay station, then the
  /// older random-by-artist endpoint. Used when the queue is empty — a
  /// standalone track whose seed has not landed, or an album finished with
  /// repeat off.
  Future<void> _playFromStation() async {
    try {
      final info = await _queueService.fetchNextTrack(
        state.currentTrackId,
        exclude: state.trackIdHistory,
      );
      final id = info['id'] as String? ?? '';
      if (id.isEmpty) {
        print('Station had nothing new');
        state = state.copyWith(isLoading: false, hasNextTrack: false);
        return;
      }
      // resetContext leaves any album behind and re-seeds a fresh radio queue.
      await _loadTrack(id, resetContext: true);
    } catch (e) {
      print('Error playing from station: $e');
      state = state.copyWith(isLoading: false, hasNextTrack: false);
    }
  }

  /// True while the radio queue is short enough to be worth topping up. Album
  /// queues are fixed, so they are never topped up.
  bool _shouldPrefetchNextTrack() =>
      state.contextTracks.isEmpty && state.queue.length < 3;

  /// Fills the radio queue when it is empty (seed) or getting short (top up),
  /// from the same station list the Up-next UI shows. No-op for album queues,
  /// which are fixed. Guarded so overlapping calls (seed on load + prefetch on
  /// position) don't double-fetch.
  Future<void> _ensureQueueReady() async {
    if (_queueBusy) return;
    if (state.contextTracks.isNotEmpty) return;
    if (state.queue.length >= 3) return;

    final seed = state.currentTrackId;
    if (seed.isEmpty) return;

    _queueBusy = true;
    state = state.copyWith(isNextTrackLoading: true);
    try {
      final exclude = <String>[
        ...state.trackIdHistory,
        ...state.queue.map((t) => t['id'] as String? ?? ''),
      ];
      final more = await _queueService.fetchStationQueue(
        seed,
        exclude: exclude,
      );

      // An album may have taken over while we were fetching.
      if (state.contextTracks.isNotEmpty) return;

      final have = <String>{seed, ...exclude};
      final merged = List<Map<String, dynamic>>.of(state.queue);
      for (final t in more) {
        final id = t['id'] as String? ?? '';
        if (id.isNotEmpty && have.add(id)) merged.add(t);
      }
      state = state.copyWith(
        queue: merged,
        queueOrigin: state.queueOrigin.isEmpty ? 'Radio' : state.queueOrigin,
        hasNextTrack: merged.isNotEmpty,
      );
    } catch (e) {
      print('Error readying queue: $e');
    } finally {
      _queueBusy = false;
      state = state.copyWith(isNextTrackLoading: false);
    }
  }

  /// Prefetch hook fired from position updates — just keeps the queue ready.
  Future<void> _prefetchNextTrack() => _ensureQueueReady();

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

  /// Plays a single track on its own — from search, the home rows, the library.
  ///
  /// This leaves whatever album context was playing and starts a fresh radio
  /// queue seeded from [trackId], so "next" continues in that track's world.
  Future<void> loadTrack(String trackId, {bool addToHistory = true}) async {
    await _loadTrack(trackId, addToHistory: addToHistory, resetContext: true);
  }

  /// Plays [tracks] as an ordered context (an album), starting at [startIndex].
  ///
  /// The remaining tracks become the queue and the full list is remembered so
  /// repeat-all can loop it. This is what makes "play an album" actually play
  /// the album through rather than wandering off into the station.
  Future<void> playAlbum(
    List<Map<String, dynamic>> tracks,
    int startIndex, {
    String albumName = '',
  }) async {
    if (tracks.isEmpty) return;
    final start = startIndex.clamp(0, tracks.length - 1);

    state = state.copyWith(
      contextTracks: List.of(tracks),
      queue: tracks.sublist(start + 1),
      queueOrigin: albumName.isEmpty ? 'Album' : albumName,
    );

    final id = tracks[start]['id'] as String? ?? '';
    await _loadTrack(id, resetContext: false);
  }

  /// Jumps to the queue entry at [index], dropping everything before it so the
  /// tracks after it stay queued. Used when tapping an Up-next row.
  Future<void> playQueueItemAt(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    final item = Map<String, dynamic>.of(state.queue[index]);
    final id = item['id'] as String? ?? '';
    if (id.isEmpty) return;

    state = state.copyWith(queue: state.queue.sublist(index + 1));
    await _loadTrack(id, resetContext: false);
    unawaited(_ensureQueueReady());
  }

  /// Loads and plays [trackId].
  ///
  /// [historyIndex] moves the pointer to an entry that is already in the
  /// history, for prev/next navigation. Without it the pointer would stay put
  /// and the track would be written over the slot the listener is currently on,
  /// which makes every later "next" replay the same song.
  ///
  /// [resetContext] leaves any album behind and seeds a fresh radio queue —
  /// set for standalone plays, cleared when the caller is itself managing the
  /// queue (album playback, queue advance, jumping within the queue).
  Future<void> _loadTrack(
    String trackId, {
    bool addToHistory = true,
    int? historyIndex,
    bool resetContext = false,
  }) async {
    try {
      // Ensure keyboard is hidden and bottom player is visible
      if (_ref.read(searchStateProvider.notifier).state.isKeyboardVisible) {
        _ref.read(searchStateProvider.notifier).setKeyboardVisible(false);
      }

      // Don't proceed if trackId is empty
      if (trackId.isEmpty) return;

      // A standalone play leaves any album behind and drops its queue; the
      // radio queue is re-seeded from the new track once its data lands.
      if (resetContext) {
        state = state.copyWith(
          queue: const [],
          contextTracks: const [],
          queueOrigin: '',
        );
      }

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
        HistoryService()
            .recordTrack(
              id: trackId,
              title: trackInfo['title'] as String,
              artist: trackInfo['artist'] as String,
              artistId: trackInfo['artistId'] as String,
              imageUrl: trackInfo['imageUrl'] as String,
            )
            .catchError((e) {
              print('Failed to record track in history: $e');
            }),
      );

      // Same for the artist, which is what fills the artists shelf on Home
      // and the Artists filter in the library.
      final artistId = trackInfo['artistId'] as String;
      if (artistId.isNotEmpty) {
        unawaited(
          HistoryService()
              .recordArtist(id: artistId, name: trackInfo['artist'] as String)
              .catchError((e) {
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

      // A standalone play starts a fresh radio queue from this track. Album
      // and queue-advance plays manage their own queue and skip this.
      if (resetContext) unawaited(_ensureQueueReady());

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

    // The Next button skips even in repeat-one, so it always advances the
    // queue rather than replaying.
    if (_isSwitchingTrack) {
      print('Already switching track, ignoring');
      return;
    }
    _isSwitchingTrack = true;
    try {
      await _advance();
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
      final restored =
          state.volumeBeforeMute > 0 ? state.volumeBeforeMute : 1.0;
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
    // Otherwise the lock screen keeps offering controls for a player that is
    // no longer there.
    MediaSession.instance.clear();
    super.dispose();
  }
}
