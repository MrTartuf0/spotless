import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'dart:io';
import 'dart:async';

class AudioService {
  // Singleton instance
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  // Private constructor
  AudioService._internal();

  // Platform-specific players
  AudioPlayer? _iosAudioPlayer;
  just_audio.AudioPlayer? _androidAudioPlayer;

  // Track the current URL and position
  String? _currentUrl;
  Duration _currentPosition = Duration.zero;

  // State flags
  bool _isPlaying = false;
  bool _isDisposed = false;
  bool _isInitialized = false;

  // Listeners for state changes
  final List<Function(PlayerState)> _playerStateListeners = [];
  final List<Function(Duration)> _positionListeners = [];
  final List<Function(Duration)> _durationListeners = [];
  final List<Function()> _completionListeners = [];

  // Platform detection
  bool get _useAndroidPlayer => Platform.isAndroid;

  // Initialize players
  Future<void> _initialize() async {
    if (_isInitialized) return;

    print('Initializing AudioService');

    if (_useAndroidPlayer) {
      _androidAudioPlayer = just_audio.AudioPlayer();
      _setupAndroidListeners();
    } else {
      _iosAudioPlayer = AudioPlayer();
      _setupIosListeners();
    }

    _isInitialized = true;
  }

  // Completely release all resources and reinitialize
  Future<void> _fullReset() async {
    print('Performing full reset of AudioService');

    // First, release all resources
    await _releaseResources();

    // Then reinitialize
    _isInitialized = false;
    await _initialize();

    // Reset state
    _currentUrl = null;
    _currentPosition = Duration.zero;
    _isPlaying = false;
  }

  // Release all resources
  Future<void> _releaseResources() async {
    print('Releasing all audio resources');

    if (_useAndroidPlayer) {
      if (_androidAudioPlayer != null) {
        try {
          print('Stopping Android player');
          await _androidAudioPlayer!.stop();
          print('Disposing Android player');
          await _androidAudioPlayer!.dispose();
        } catch (e) {
          print('Error releasing Android player: $e');
        } finally {
          _androidAudioPlayer = null;
        }
      }
    } else {
      if (_iosAudioPlayer != null) {
        try {
          print('Stopping iOS player');
          await _iosAudioPlayer!.stop();
          print('Disposing iOS player');
          await _iosAudioPlayer!.dispose();
        } catch (e) {
          print('Error releasing iOS player: $e');
        } finally {
          _iosAudioPlayer = null;
        }
      }
    }

    _isInitialized = false;
  }

  // Set up listeners for the Android player
  void _setupAndroidListeners() {
    if (_androidAudioPlayer == null) return;

    print('Setting up Android listeners');

    // Player state listener
    _androidAudioPlayer!.playerStateStream.listen((state) {
      final playerState =
          state.playing
              ? PlayerState.playing
              : (state.processingState == just_audio.ProcessingState.loading
                  ? PlayerState.playing
                  : PlayerState.stopped);

      _isPlaying = state.playing;

      print(
        'Android player state changed: ${state.playing ? "playing" : "paused"}, '
        'process: ${state.processingState}',
      );

      for (var listener in _playerStateListeners) {
        listener(playerState);
      }
    });

    // Position listener
    _androidAudioPlayer!.positionStream.listen((position) {
      _currentPosition = position;

      for (var listener in _positionListeners) {
        listener(position);
      }
    });

    // Duration listener
    _androidAudioPlayer!.durationStream.listen((duration) {
      if (duration != null) {
        print('Duration reported: ${duration.inSeconds} seconds');
        for (var listener in _durationListeners) {
          listener(duration);
        }
      }
    });

    // Completion listener
    _androidAudioPlayer!.processingStateStream.listen((state) {
      if (state == just_audio.ProcessingState.completed) {
        print('Playback completed');
        _currentPosition = Duration.zero;

        for (var listener in _completionListeners) {
          listener();
        }
      }
    });
  }

  // Set up listeners for the iOS player
  void _setupIosListeners() {
    if (_iosAudioPlayer == null) return;

    print('Setting up iOS listeners');

    _iosAudioPlayer!.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;

      print('iOS player state changed: $state');

      for (var listener in _playerStateListeners) {
        listener(state);
      }
    });

    _iosAudioPlayer!.onPositionChanged.listen((position) {
      _currentPosition = position;

      for (var listener in _positionListeners) {
        listener(position);
      }
    });

    _iosAudioPlayer!.onDurationChanged.listen((duration) {
      print('Duration reported: ${duration.inSeconds} seconds');

      for (var listener in _durationListeners) {
        listener(duration);
      }
    });

    _iosAudioPlayer!.onPlayerComplete.listen((_) {
      print('Playback completed');
      _currentPosition = Duration.zero;

      for (var listener in _completionListeners) {
        listener();
      }
    });
  }

  // Register listeners
  void addPlayerStateListener(Function(PlayerState) listener) {
    _playerStateListeners.add(listener);
  }

  void addPositionListener(Function(Duration) listener) {
    _positionListeners.add(listener);
  }

  void addDurationListener(Function(Duration) listener) {
    _durationListeners.add(listener);
  }

  void addCompletionListener(Function() listener) {
    _completionListeners.add(listener);
  }

  // Play a URL - completely resets the player for each new track
  Future<void> play(String url, {bool fromBeginning = true}) async {
    try {
      print('Playing URL: $url (fromBeginning: $fromBeginning)');

      // If the URL is different or we're starting from beginning, do a full reset
      bool needsReset = url != _currentUrl || fromBeginning;

      if (needsReset) {
        print('URL changed or starting from beginning, doing full reset');
        await _fullReset();
        _currentUrl = url;
      }

      // Make sure we're initialized
      if (!_isInitialized) {
        await _initialize();
      }

      // Get the position to start from
      final position = fromBeginning ? Duration.zero : _currentPosition;

      if (_useAndroidPlayer) {
        if (_androidAudioPlayer == null) {
          print('Android player is null, initializing');
          await _initialize();
        }

        // Always set the URL when playing a track
        print('Setting URL on Android player: $url');
        await _androidAudioPlayer!.setUrl(url);

        // Seek if needed
        if (!fromBeginning && position > Duration.zero) {
          print('Seeking to position: ${position.inSeconds} seconds');
          await _androidAudioPlayer!.seek(position);
        }

        // Start playback
        print('Starting Android playback');
        await _androidAudioPlayer!.play();
      } else {
        if (_iosAudioPlayer == null) {
          print('iOS player is null, initializing');
          await _initialize();
        }

        // Always play with the URL for iOS
        print('Starting iOS playback with URL: $url');
        await _iosAudioPlayer!.play(UrlSource(url));

        // Seek if needed
        if (!fromBeginning && position > Duration.zero) {
          print('Seeking to position: ${position.inSeconds} seconds');
          await _iosAudioPlayer!.seek(position);
        }
      }
    } catch (e) {
      print('Error playing audio: $e');
      rethrow;
    }
  }

  // Pause playback
  Future<void> pause() async {
    try {
      print('Pausing playback');

      if (!_isInitialized) {
        print('Audio player not initialized, nothing to pause');
        return;
      }

      if (_useAndroidPlayer) {
        if (_androidAudioPlayer != null) {
          // Save position before pausing
          _currentPosition = await _androidAudioPlayer!.position;
          print(
            'Saving position before pause: ${_currentPosition.inSeconds} seconds',
          );

          await _androidAudioPlayer!.pause();
        }
      } else {
        if (_iosAudioPlayer != null) {
          // Save position before pausing
          _currentPosition =
              await _iosAudioPlayer!.getCurrentPosition() ?? Duration.zero;
          print(
            'Saving position before pause: ${_currentPosition.inSeconds} seconds',
          );

          await _iosAudioPlayer!.pause();
        }
      }
    } catch (e) {
      print('Error pausing: $e');
    }
  }

  // Resume playback
  Future<void> resume() async {
    try {
      print('Resuming playback');

      if (!_isInitialized || _currentUrl == null) {
        print('Audio player not initialized or no URL set, cannot resume');
        return;
      }

      if (_useAndroidPlayer) {
        if (_androidAudioPlayer != null) {
          if (_androidAudioPlayer!.playing) {
            print('Android player already playing');
            return;
          }

          print(
            'Resuming Android playback from position: ${_currentPosition.inSeconds} seconds',
          );
          await _androidAudioPlayer!.seek(_currentPosition);
          await _androidAudioPlayer!.play();
        } else {
          print('Android player is null, restarting playback');
          await play(_currentUrl!, fromBeginning: false);
        }
      } else {
        if (_iosAudioPlayer != null) {
          print('Resuming iOS playback');
          await _iosAudioPlayer!.resume();
        } else {
          print('iOS player is null, restarting playback');
          await play(_currentUrl!, fromBeginning: false);
        }
      }
    } catch (e) {
      print('Error resuming: $e');
    }
  }

  // Stop playback
  Future<void> stop() async {
    try {
      print('Stopping playback');

      if (!_isInitialized) {
        print('Audio player not initialized, nothing to stop');
        return;
      }

      if (_useAndroidPlayer) {
        if (_androidAudioPlayer != null) {
          // Save position before stopping
          _currentPosition = await _androidAudioPlayer!.position;
          print(
            'Saving position before stop: ${_currentPosition.inSeconds} seconds',
          );

          await _androidAudioPlayer!.stop();
        }
      } else {
        if (_iosAudioPlayer != null) {
          // Save position before stopping
          _currentPosition =
              await _iosAudioPlayer!.getCurrentPosition() ?? Duration.zero;
          print(
            'Saving position before stop: ${_currentPosition.inSeconds} seconds',
          );

          await _iosAudioPlayer!.stop();
        }
      }
    } catch (e) {
      print('Error stopping: $e');
    }
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    try {
      print('Seeking to position: ${position.inSeconds} seconds');

      if (!_isInitialized) {
        print('Audio player not initialized, cannot seek');
        _currentPosition = position; // Still update the stored position
        return;
      }

      // Immediately update our tracked position
      _currentPosition = position;

      if (_useAndroidPlayer) {
        if (_androidAudioPlayer != null) {
          await _androidAudioPlayer!.seek(position);
        }
      } else {
        if (_iosAudioPlayer != null) {
          await _iosAudioPlayer!.seek(position);
        }
      }
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  // Get current position
  Future<Duration> getCurrentPosition() async {
    try {
      if (!_isInitialized) {
        return _currentPosition;
      }

      if (_useAndroidPlayer) {
        if (_androidAudioPlayer != null) {
          return await _androidAudioPlayer!.position;
        }
      } else {
        if (_iosAudioPlayer != null) {
          return await _iosAudioPlayer!.getCurrentPosition() ??
              _currentPosition;
        }
      }
    } catch (e) {
      print('Error getting position: $e');
    }
    return _currentPosition;
  }

  // Dispose all resources
  Future<void> dispose() async {
    print('Disposing AudioService');
    _isDisposed = true;

    // Clear all listeners
    _playerStateListeners.clear();
    _positionListeners.clear();
    _durationListeners.clear();
    _completionListeners.clear();

    // Release resources
    await _releaseResources();
  }

  // Current state
  PlayerState get currentState {
    if (!_isInitialized) return PlayerState.stopped;

    if (_useAndroidPlayer) {
      if (_androidAudioPlayer == null) return PlayerState.stopped;
      return _androidAudioPlayer!.playing
          ? PlayerState.playing
          : PlayerState.stopped;
    } else {
      if (_iosAudioPlayer == null) return PlayerState.stopped;
      return _iosAudioPlayer!.state;
    }
  }
}
