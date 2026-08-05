// lib/providers/audio_player/audio_player_state.dart
import 'package:flutter/material.dart';

class AudioPlayerState {
  final int index;
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

  // Fields for prefetched next track
  //final String nextTrackId;
  //final String nextTrackTitle;
  //final String nextTrackArtist;
  //final String nextTrackImage;
  //final String nextStreamUrl;
  final bool isNextTrackLoading;
  final bool hasNextTrack;

  final bool isTrackEnding;
  final List<String> trackIdHistory;

  /// Output level, 0..1.
  final double volume;

  /// Level to restore when unmuting. Muting is "volume 0 with a memory"
  /// rather than a separate flag on the player.
  final double volumeBeforeMute;

  const AudioPlayerState({
    this.volume = 1.0,
    this.volumeBeforeMute = 1.0,
    this.isNextTrackLoading = false,
    this.hasNextTrack = false,
    this.index = -1,
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
    this.isTrackEnding = false,
    this.trackIdHistory = const [],
  });

  AudioPlayerState copyWith({
    int? index,
    bool? hasNextTrack,
    bool? isNextTrackLoading,
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
    bool? isTrackEnding,
    List<String>? trackIdHistory,
    double? volume,
    double? volumeBeforeMute,
  }) {
    return AudioPlayerState(
      volume: volume ?? this.volume,
      volumeBeforeMute: volumeBeforeMute ?? this.volumeBeforeMute,
      hasNextTrack: hasNextTrack ?? this.hasNextTrack,
      index: index ?? this.index,
      isNextTrackLoading: isNextTrackLoading ?? this.isNextTrackLoading,
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
      isTrackEnding: isTrackEnding ?? this.isTrackEnding,
      trackIdHistory: trackIdHistory ?? this.trackIdHistory,
    );
  }

  double get progress {
    if (totalDuration.inMilliseconds > 0) {
      return currentPosition.inMilliseconds / totalDuration.inMilliseconds;
    }
    return 0.0;
  }
}
