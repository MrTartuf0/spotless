import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart' as ads;
import 'package:flutter/foundation.dart';

/// Bridges playback to the OS media session: the iOS lock screen and Control
/// Center, the CarPlay Now Playing screen, Android's notification and Android
/// Auto, the Linux desktop's MPRIS player, plus headphone, steering-wheel and
/// keyboard media buttons.
///
/// This deliberately owns no playback of its own. [AudioPlayerNotifier] stays
/// the single source of truth: it pushes the current track and playback state
/// in through [setItem]/[setPlaybackState], and remote buttons come back out
/// through the callbacks registered with [attach].
///
/// Everywhere without a session (Windows, macOS, web, tests) every method is a
/// no-op, so callers never need to check.
class MediaSession {
  static final MediaSession instance = MediaSession._();

  MediaSession._();

  _SpotlessAudioHandler? _handler;

  /// True where the plugin actually has an implementation: the native sessions
  /// on Android and iOS, and MPRIS over D-Bus on Linux via
  /// `audio_service_mpris`, which Flutter registers for us on that platform.
  ///
  /// Linux is what makes the keyboard's media keys work. Compositors and
  /// desktop environments grab those keys themselves and forward them to
  /// whichever process claims the MPRIS bus name — they never arrive as key
  /// events, so being on that bus is the only way to receive them.
  static bool get isSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  // Remote commands, filled in by [attach].
  VoidCallback? _onPlay;
  VoidCallback? _onPause;
  VoidCallback? _onNext;
  VoidCallback? _onPrevious;
  VoidCallback? _onStop;
  void Function(Duration position)? _onSeek;

  /// Starts the media session. Must be awaited before `runApp`, because the
  /// plugin has to be ready before the OS can bind to the service.
  Future<void> init() async {
    if (!isSupported || _handler != null) return;

    try {
      _handler = await ads.AudioService.init(
        builder: () => _SpotlessAudioHandler(this),
        config: const ads.AudioServiceConfig(
          androidNotificationChannelId: 'com.example.spotACrack.playback',
          androidNotificationChannelName: 'Playback',
          // Keep the notification up while paused, so the transport controls
          // stay reachable instead of vanishing mid-song.
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: true,
        ),
      );
    } catch (e) {
      // A missing platform implementation must never stop the app booting.
      print('Media session unavailable: $e');
    }
  }

  /// Registers the handlers for remote transport commands.
  void attach({
    required VoidCallback onPlay,
    required VoidCallback onPause,
    required VoidCallback onNext,
    required VoidCallback onPrevious,
    required VoidCallback onStop,
    required void Function(Duration position) onSeek,
  }) {
    _onPlay = onPlay;
    _onPause = onPause;
    _onNext = onNext;
    _onPrevious = onPrevious;
    _onStop = onStop;
    _onSeek = onSeek;
  }

  /// Publishes what is playing: title, artist, album, artwork and duration.
  ///
  /// This is what the lock screen and the CarPlay Now Playing screen render.
  void setItem({
    required String id,
    required String title,
    required String artist,
    required String album,
    required String artworkUrl,
    required Duration duration,
  }) {
    final handler = _handler;
    if (handler == null || id.isEmpty) return;

    handler.mediaItem.add(
      ads.MediaItem(
        id: id,
        title: title.isEmpty ? 'Unknown track' : title,
        artist: artist.isEmpty ? null : artist,
        album: album.isEmpty ? null : album,
        duration: duration > Duration.zero ? duration : null,
        // The plugin fetches and caches this for the lock screen artwork.
        artUri: artworkUrl.startsWith('http') ? Uri.tryParse(artworkUrl) : null,
      ),
    );
  }

  /// Publishes the transport state — which button to draw, and where the
  /// scrubber sits.
  void setPlaybackState({
    required bool playing,
    required bool loading,
    required Duration position,
    required bool hasPrevious,
  }) {
    final handler = _handler;
    if (handler == null) return;

    handler.playbackState.add(
      ads.PlaybackState(
        controls: [
          if (hasPrevious) ads.MediaControl.skipToPrevious,
          if (playing) ads.MediaControl.pause else ads.MediaControl.play,
          ads.MediaControl.skipToNext,
        ],
        systemActions: const {
          ads.MediaAction.seek,
          ads.MediaAction.seekForward,
          ads.MediaAction.seekBackward,
        },
        // Which of the controls above Android shows in the collapsed
        // notification.
        androidCompactActionIndices: const [0, 1, 2],
        processingState: loading
            ? ads.AudioProcessingState.loading
            : ads.AudioProcessingState.ready,
        playing: playing,
        updatePosition: position,
      ),
    );
  }

  /// Clears the session — the lock screen entry goes away.
  void clear() {
    _handler?.playbackState.add(
      ads.PlaybackState(
        processingState: ads.AudioProcessingState.idle,
        playing: false,
      ),
    );
  }
}

/// Receives the remote commands and forwards them. Every override is a
/// one-liner on purpose: the real logic lives in the notifier.
class _SpotlessAudioHandler extends ads.BaseAudioHandler with ads.SeekHandler {
  final MediaSession _session;

  _SpotlessAudioHandler(this._session);

  @override
  Future<void> play() async => _session._onPlay?.call();

  @override
  Future<void> pause() async => _session._onPause?.call();

  @override
  Future<void> skipToNext() async => _session._onNext?.call();

  @override
  Future<void> skipToPrevious() async => _session._onPrevious?.call();

  @override
  Future<void> seek(Duration position) async => _session._onSeek?.call(position);

  @override
  Future<void> stop() async {
    _session._onStop?.call();
    await super.stop();
  }
}
