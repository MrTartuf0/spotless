// lib/providers/audio_player_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:rick_spot/repositories/track_repository.dart';

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

  const AudioPlayerState({
    this.isPlaying = false,
    this.isLoading = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.currentTrackTitle = 'Dani California',
    this.currentTrackArtist = 'Red Hot Chili Peppers',
    this.currentTrackImage =
        'https://i.scdn.co/image/ab67616d00001e0209fd83d32aee93dceba78517',
    this.currentStreamUrl =
        'https://spc.rickyscloud.com/hls/94599360893856627734266258834711005588.m3u8',
    this.currentAlbumName = 'Blood Sugar Sex Magik (Deluxe Edition)',
    this.currentTrackId = '3d9DChrdc6BOeFsbrZ3Is0',
    this.isLiked = true,
    this.isShuffled = false,
    this.repeatMode = 0,
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
    bool? isLiked,
    bool? isShuffled,
    int? repeatMode,
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
      isLiked: isLiked ?? this.isLiked,
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
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
  late AudioPlayer _audioPlayer;
  final TrackRepository _trackRepository;

  AudioPlayerNotifier(this._trackRepository) : super(const AudioPlayerState()) {
    _initializeAudioPlayer();
    // Load the default track data when initialized
    loadTrack(state.currentTrackId);
  }

  void _initializeAudioPlayer() {
    _audioPlayer = AudioPlayer();

    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((PlayerState playerState) {
      state = state.copyWith(
        isPlaying: playerState == PlayerState.playing,
        isLoading: playerState == PlayerState.playing ? false : state.isLoading,
      );
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((Duration position) {
      state = state.copyWith(currentPosition: position);
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      state = state.copyWith(totalDuration: duration);
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((_) {
      state = state.copyWith(isPlaying: false, currentPosition: Duration.zero);
    });
  }

  // Update only the loadTrack method in the AudioPlayerNotifier class
  Future<void> loadTrack(String trackId) async {
    try {
      state = state.copyWith(isLoading: true);

      // Get track data
      final trackData = await _trackRepository.getTrack(trackId);

      // Get the correct stream URL for this track
      final streamUrl = await _trackRepository.getStreamUrl(trackId);

      // Extract needed information from track data
      final artist = trackData['artists'][0]['name'] as String;
      final title = trackData['name'] as String;
      final imageUrl = trackData['album']['images'][0]['url'] as String;
      final albumName = trackData['album']['name'] as String;
      final durationMs = trackData['duration_ms'] as int;

      // Update the state with the track data and correct stream URL
      state = state.copyWith(
        currentTrackId: trackId,
        currentTrackTitle: title,
        currentTrackArtist: artist,
        currentTrackImage: imageUrl,
        currentAlbumName: albumName,
        totalDuration: Duration(milliseconds: durationMs),
        currentStreamUrl: streamUrl,
      );

      // Start playing the track with the correct stream URL
      await playStream();
    } catch (e) {
      print('Error loading track: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> playStream() async {
    try {
      state = state.copyWith(isLoading: true);

      // Stop any currently playing audio
      await _audioPlayer.stop();

      // Play the new stream
      await _audioPlayer.play(UrlSource(state.currentStreamUrl));
    } catch (e) {
      print('Error playing HLS stream: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (state.isPlaying) {
        await _audioPlayer.pause();
      } else {
        state = state.copyWith(isLoading: true);

        if (_audioPlayer.state == PlayerState.stopped) {
          await playStream();
        } else {
          await _audioPlayer.resume();
          state = state.copyWith(isLoading: false);
        }
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
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
    _audioPlayer.dispose();
    super.dispose();
  }
}

// Provider
final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      final trackRepository = ref.watch(trackRepositoryProvider);
      return AudioPlayerNotifier(trackRepository);
    });

// Current track ID provider
final currentTrackIdProvider = StateProvider<String>((ref) {
  return '3d9DChrdc6BOeFsbrZ3Is0'; // Default track ID
});
