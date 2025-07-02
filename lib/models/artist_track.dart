class ArtistTrack {
  final String id;
  final String name;
  final String imageUrl;
  final String albumName;
  final String duration;
  final bool isPlayable;

  ArtistTrack({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.albumName,
    required this.duration,
    required this.isPlayable,
  });

  factory ArtistTrack.fromJson(Map<String, dynamic> json) {
    // Get the image URL from album
    final albumImages = json['album']['images'] as List;
    final imageUrl = albumImages.isNotEmpty ? albumImages[0]['url'] : '';

    // Convert duration from milliseconds to MM:SS format
    final durationMs = json['duration_ms'] as int;
    final minutes = (durationMs / 60000).floor();
    final seconds = ((durationMs % 60000) / 1000).floor().toString().padLeft(
      2,
      '0',
    );
    final duration = "$minutes:$seconds";

    return ArtistTrack(
      id: json['id'],
      name: json['name'],
      imageUrl: imageUrl,
      albumName: json['album']['name'],
      duration: duration,
      isPlayable: json['is_playable'] ?? false,
    );
  }
}
