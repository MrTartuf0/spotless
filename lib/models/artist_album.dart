class ArtistAlbum {
  final String id;
  final String name;
  final String imageUrl;
  final String releaseDate;
  final int totalTracks;

  ArtistAlbum({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.releaseDate,
    required this.totalTracks,
  });

  factory ArtistAlbum.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List;
    final imageUrl = images.isNotEmpty ? images[0]['url'] : '';

    return ArtistAlbum(
      id: json['id'],
      name: json['name'],
      imageUrl: imageUrl,
      releaseDate: json['release_date'],
      totalTracks: json['total_tracks'],
    );
  }
}
