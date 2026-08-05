class Album {
  final String id;
  final String name;
  final String artist;
  final String artistId;
  final String imageUrl;
  final List<AlbumTrack> tracks;

  const Album({
    required this.id,
    required this.name,
    required this.artist,
    required this.artistId,
    required this.imageUrl,
    required this.tracks,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    final album = (json['album'] as Map<String, dynamic>?) ?? json;
    final trackList = (json['tracks'] as List? ?? const []);

    // `artists` has been seen as both List<String> (e.g. ["Pitbull"]) and
    // List<Map> (e.g. [{id, name}]) across endpoints — handle both.
    final artistsRaw = album['artists'];
    String artistName = '';
    String artistId = '';
    if (artistsRaw is List && artistsRaw.isNotEmpty) {
      final first = artistsRaw.first;
      if (first is String) {
        artistName = first;
      } else if (first is Map) {
        artistName = (first['name'] as String?) ?? '';
        artistId = (first['id'] as String?) ?? '';
      }
    }
    if (artistName.isEmpty) {
      artistName = (album['artist'] as String?) ?? '';
    }

    return Album(
      id: (album['album_id'] ?? album['id'] ?? '') as String,
      name: (album['album_name'] ?? album['name'] ?? '') as String,
      artist: artistName,
      artistId: artistId,
      imageUrl: (album['image_uri'] ?? album['imageUrl'] ?? '') as String,
      tracks: trackList
          .map((t) => AlbumTrack.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AlbumTrack {
  final String id;
  final String name;
  final String artist;
  final int durationMs;
  final String imageUrl;

  const AlbumTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.durationMs,
    required this.imageUrl,
  });

  factory AlbumTrack.fromJson(Map<String, dynamic> json) {
    return AlbumTrack(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? json['title'] ?? '') as String,
      artist: (json['artist'] ?? '') as String,
      // API uses `duration` (milliseconds) — fall back to `duration_ms` for safety.
      durationMs: ((json['duration_ms'] ?? json['duration']) as num?)?.toInt() ?? 0,
      imageUrl: (json['image_uri'] ?? json['imageUrl'] ?? '') as String,
    );
  }

  String get formattedDuration {
    final seconds = (durationMs / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainder = seconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }
}
