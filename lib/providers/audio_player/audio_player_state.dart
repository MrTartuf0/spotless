// lib/providers/audio_player/audio_player_state.dart
import 'package:flutter/material.dart';

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

  // Fields for prefetched next track
  final String nextTrackId;
  final String nextTrackTitle;
  final String nextTrackArtist;
  final String nextTrackImage;
  final String nextStreamUrl;
  final bool isNextTrackLoading;
  final bool isTrackEnding;

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
    this.nextTrackId = '',
    this.nextTrackTitle = '',
    this.nextTrackArtist = '',
    this.nextTrackImage = '',
    this.nextStreamUrl = '',
    this.isNextTrackLoading = false,
    this.isTrackEnding = false,
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
    String? nextTrackId,
    String? nextTrackTitle,
    String? nextTrackArtist,
    String? nextTrackImage,
    String? nextStreamUrl,
    bool? isNextTrackLoading,
    bool? isTrackEnding,
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
      nextTrackId: nextTrackId ?? this.nextTrackId,
      nextTrackTitle: nextTrackTitle ?? this.nextTrackTitle,
      nextTrackArtist: nextTrackArtist ?? this.nextTrackArtist,
      nextTrackImage: nextTrackImage ?? this.nextTrackImage,
      nextStreamUrl: nextStreamUrl ?? this.nextStreamUrl,
      isNextTrackLoading: isNextTrackLoading ?? this.isNextTrackLoading,
      isTrackEnding: isTrackEnding ?? this.isTrackEnding,
    );
  }

  double get progress {
    if (totalDuration.inMilliseconds > 0) {
      return currentPosition.inMilliseconds / totalDuration.inMilliseconds;
    }
    return 0.0;
  }
}
