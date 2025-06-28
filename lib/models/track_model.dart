// lib/models/track_model.dart
class TrackModel {
  final String id;
  final String name;
  final List<Artist> artists;
  final Album album;
  final int durationMs;
  final String streamUrl;

  TrackModel({
    required this.id,
    required this.name,
    required this.artists,
    required this.album,
    required this.durationMs,
    this.streamUrl = '',
  });

  String get artistName => artists.map((artist) => artist.name).join(', ');
  String get imageUrl => album.images.isNotEmpty ? album.images[0].url : '';
  Duration get duration => Duration(milliseconds: durationMs);

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: json['id'] as String,
      name: json['name'] as String,
      artists:
          (json['artists'] as List)
              .map((artist) => Artist.fromJson(artist))
              .toList(),
      album: Album.fromJson(json['album']),
      durationMs: json['duration_ms'] as int,
    );
  }
}

class Artist {
  final String id;
  final String name;

  Artist({required this.id, required this.name});

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(id: json['id'] as String, name: json['name'] as String);
  }
}

class Album {
  final String id;
  final String name;
  final List<Image> images;

  Album({required this.id, required this.name, required this.images});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String,
      name: json['name'] as String,
      images:
          (json['images'] as List)
              .map((image) => Image.fromJson(image))
              .toList(),
    );
  }
}

class Image {
  final String url;
  final int width;
  final int height;

  Image({required this.url, required this.width, required this.height});

  factory Image.fromJson(Map<String, dynamic> json) {
    return Image(
      url: json['url'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }
}
