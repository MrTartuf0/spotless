// lib/providers/audio_player/track_completion_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

class TrackCompletionService {
  // Track position thresholds
  static const double prefetchThreshold = 0.70;
  static const double nearEndThreshold = 0.95;
  static const double forceNextThreshold = 0.995; // Force next track at 99.5%
  static const int endOfTrackTimeoutMs = 3000;
  static const int forceNextTimeoutMs =
      1000; // Shorter timeout for forcing next

  // Timers
  Timer? _trackEndTimer;
  Timer? _watchdogTimer;
  Timer? _pollingTimer; // Additional polling timer

  // State flags
  bool _handlingTrackEnd = false;
  bool _completionHandled = false;

  // Callbacks
  final VoidCallback onTrackComplete;
  final VoidCallback onPrefetchNeeded;
  final Function(double) progressChecker; // Function to check current progress

  TrackCompletionService({
    required this.onTrackComplete,
    required this.onPrefetchNeeded,
    required this.progressChecker,
  }) {
    // Start polling timer that checks track state regularly
    _startPollingTimer();
  }

  // Start a polling timer that periodically checks if we need to force track advancement
  void _startPollingTimer() {
    cancelPollingTimer();

    // Check every 1 second if we should advance the track
    _pollingTimer = Timer.periodic(Duration(milliseconds: 1000), (_) {
      final progress = progressChecker(0);

      // If we're very near the end and not handling completion, force advance
      if (progress > 0.995 && !_completionHandled && !_handlingTrackEnd) {
        print(
          "🔍 POLLING TIMER: Track at ${(progress * 100).toStringAsFixed(1)}%, forcing next track",
        );
        _completionHandled = true;
        onTrackComplete();
      }
    });
  }

  void cancelPollingTimer() {
    if (_pollingTimer != null && _pollingTimer!.isActive) {
      _pollingTimer!.cancel();
      _pollingTimer = null;
    }
  }

  bool get isHandlingTrackEnd => _handlingTrackEnd;

  void setHandlingTrackEnd(bool value) {
    _handlingTrackEnd = value;
  }

  bool get isCompletionHandled => _completionHandled;

  void setCompletionHandled(bool value) {
    _completionHandled = value;

    if (!value) {
      // Reset completion flag after a delay to prevent multiple triggers
      Future.delayed(Duration(seconds: 2), () {
        _completionHandled = false;
      });
    }
  }

  // Check if track progress requires prefetching
  bool shouldPrefetch(double progress) {
    return progress > prefetchThreshold;
  }

  // Check if track should be considered finished
  bool shouldForceCompletion(double progress) {
    return progress > forceNextThreshold && !_completionHandled;
  }

  // Check if we're approaching track end
  bool isNearEnd(double progress) {
    return progress > nearEndThreshold;
  }

  // Check if we need to handle track completion
  bool checkTrackCompletion(double progress) {
    if (!_completionHandled) {
      // If we're extremely close to the end (99.5%+), force next track immediately
      if (progress > forceNextThreshold) {
        print(
          "Track at ${(progress * 100).toStringAsFixed(1)}%, forcing immediate transition to next track",
        );
        _completionHandled = true;
        onTrackComplete();
        return true;
      }
      // Otherwise check normally at 97%+
      else if (progress > 0.97) {
        print("Track seems to have completed based on position checks");
        _completionHandled = true;
        onTrackComplete();
        return true;
      }
    }
    return false;
  }

  // Schedule a timer to check if track ended properly
  void scheduleEndOfTrackTimer(
    double progress,
    Duration totalDuration,
    Duration currentPosition,
  ) {
    cancelTrackEndTimer();

    print(
      "Near end of track (${(progress * 100).toStringAsFixed(1)}%), scheduling end timer",
    );

    // Schedule a more aggressive timer if we're very close to the end
    final timeoutMs =
        (progress > forceNextThreshold)
            ? forceNextTimeoutMs // Use shorter timeout if we're very close to end
            : endOfTrackTimeoutMs;

    // Calculate remaining time plus a small buffer
    final remainingMs = (totalDuration.inMilliseconds -
            currentPosition.inMilliseconds +
            500)
        .clamp(timeoutMs ~/ 2, timeoutMs);

    // Schedule timer
    _trackEndTimer = Timer(Duration(milliseconds: remainingMs), () {
      print("End of track timer fired, checking if track completed");
      checkTrackCompletion(progress);
    });
  }

  // Cancel the track end timer
  void cancelTrackEndTimer() {
    if (_trackEndTimer != null && _trackEndTimer!.isActive) {
      _trackEndTimer!.cancel();
      _trackEndTimer = null;
    }
  }

  // Set up a watchdog timer that will force advancement if all else fails
  void setupWatchdogTimer(Duration totalDuration, bool isPlaying) {
    cancelWatchdogTimer();

    // Only set up watchdog if we know the duration
    if (totalDuration.inMilliseconds > 0 && isPlaying) {
      // Set timer for slightly after the expected end time
      final timeoutMs =
          totalDuration.inMilliseconds + 2000; // 2 seconds after expected end

      _watchdogTimer = Timer(Duration(milliseconds: timeoutMs), () {
        print("🔴 WATCHDOG TIMER FIRED - FORCING TRACK ADVANCEMENT 🔴");
        if (!_completionHandled) {
          _completionHandled = true;
          onTrackComplete();
        }
      });

      print("Watchdog timer set for ${timeoutMs / 1000} seconds");
    }
  }

  void cancelWatchdogTimer() {
    if (_watchdogTimer != null && _watchdogTimer!.isActive) {
      _watchdogTimer!.cancel();
      _watchdogTimer = null;
    }
  }

  void dispose() {
    cancelTrackEndTimer();
    cancelWatchdogTimer();
    cancelPollingTimer();
  }
}
