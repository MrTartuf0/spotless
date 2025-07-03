// lib/providers/audio_player/track_playback_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:rick_spot/services/audio_service.dart';

class TrackPlaybackService {
  final AudioService _audioService;

  // Callbacks
  final void Function(PlayerState) onPlayerStateChanged;
  final void Function(Duration) onPositionChanged;
  final void Function(Duration) onDurationChanged;
  final VoidCallback onTrackCompleted;

  TrackPlaybackService({
    required AudioService audioService,
    required this.onPlayerStateChanged,
    required this.onPositionChanged,
    required this.onDurationChanged,
    required this.onTrackCompleted,
  }) : _audioService = audioService {
    _initListeners();
  }

  PlayerState get currentState => _audioService.currentState;

  void _initListeners() {
    _audioService.addPlayerStateListener(onPlayerStateChanged);
    _audioService.addPositionListener(onPositionChanged);
    _audioService.addDurationListener(onDurationChanged);
    _audioService.addCompletionListener(onTrackCompleted);
  }

  Future<void> play(String url, {bool fromBeginning = true}) async {
    await _audioService.play(url, fromBeginning: fromBeginning);
  }

  Future<void> stop() async {
    await _audioService.stop();
  }

  Future<void> pause() async {
    await _audioService.pause();
  }

  Future<void> resume() async {
    await _audioService.resume();
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  String formatTime(Duration duration) {
    int mins = duration.inMinutes;
    int secs = duration.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
