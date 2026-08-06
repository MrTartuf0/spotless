/// A track's lyrics, as returned by the backend's `/api/lyrics/{id}`.
///
/// The backend normalises Spotify's color-lyrics payload: string millisecond
/// timestamps become numbers, and each line is just a time plus its text.
class Lyrics {
  final String trackId;

  /// False when the backend reports no lyrics for the track — the UI shows a
  /// plain "no lyrics" state rather than an error.
  final bool hasLyrics;

  /// Whether the lines carry real timestamps. When false, [lines] are still in
  /// order but every [LyricLine.timeMs] is 0, so the view scrolls them plainly
  /// instead of highlighting to the beat.
  final bool synced;

  final String provider;
  final bool isRtl;
  final List<LyricLine> lines;

  const Lyrics({
    required this.trackId,
    required this.hasLyrics,
    required this.synced,
    this.provider = '',
    this.isRtl = false,
    this.lines = const [],
  });

  const Lyrics.none(this.trackId)
    : hasLyrics = false,
      synced = false,
      provider = '',
      isRtl = false,
      lines = const [];

  factory Lyrics.fromJson(Map<String, dynamic> json) {
    final rawLines = (json['lines'] as List?) ?? const [];
    return Lyrics(
      trackId: (json['trackId'] as String?) ?? '',
      hasLyrics: (json['hasLyrics'] as bool?) ?? false,
      synced: (json['synced'] as bool?) ?? false,
      provider: (json['provider'] as String?) ?? '',
      isRtl: (json['isRtlLanguage'] as bool?) ?? false,
      lines:
          rawLines
              .whereType<Map>()
              .map((l) => LyricLine.fromJson(l.cast<String, dynamic>()))
              .toList(),
    );
  }

  /// Index of the line that should be active at [position], or -1 before the
  /// first timed line. Assumes lines are sorted by time, which the backend
  /// guarantees.
  int activeIndexAt(Duration position) {
    if (!synced) return -1;
    final ms = position.inMilliseconds;
    var active = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].timeMs <= ms) {
        active = i;
      } else {
        break;
      }
    }
    return active;
  }
}

class LyricLine {
  final int timeMs;
  final String words;

  const LyricLine({required this.timeMs, required this.words});

  factory LyricLine.fromJson(Map<String, dynamic> json) => LyricLine(
    timeMs: (json['timeMs'] as num?)?.toInt() ?? 0,
    words: (json['words'] as String?) ?? '',
  );
}
