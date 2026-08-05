class ArtistAlbum {
  final String id;
  final String name;
  final String imageUrl;
  final String releaseDate;
  final int totalTracks;

  /// Spotify's `album_type`: `album`, `single` or `compilation`. Kept so the
  /// artist page can group full albums separately from singles and EPs.
  final String albumType;

  ArtistAlbum({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.releaseDate,
    required this.totalTracks,
    this.albumType = 'album',
  });

  bool get isAlbum => albumType == 'album';

  /// Just the year, which is all the grid subtitle has room for.
  String get releaseYear =>
      releaseDate.length >= 4 ? releaseDate.substring(0, 4) : releaseDate;

  factory ArtistAlbum.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List?) ?? const [];
    final imageUrl =
        images.isNotEmpty ? ((images[0]['url'] as String?) ?? '') : '';

    return ArtistAlbum(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      imageUrl: imageUrl,
      releaseDate: (json['release_date'] as String?) ?? '',
      totalTracks: (json['total_tracks'] as num?)?.toInt() ?? 0,
      albumType: (json['album_type'] as String?) ?? 'album',
    );
  }
}
