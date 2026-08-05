/// Artist metadata from `GET /api/artist/{id}`.
///
/// Every field is parsed defensively: the endpoint mirrors Spotify's artist
/// object, and older/partial entries can be missing images, followers or
/// genres entirely.
class ArtistProfile {
  final String id;
  final String name;

  /// Largest artwork available, for page headers.
  final String imageUrl;

  /// Smallest artwork available, for avatars and list rows.
  final String thumbnailUrl;

  final int followers;
  final int popularity;
  final List<String> genres;

  const ArtistProfile({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.thumbnailUrl = '',
    this.followers = 0,
    this.popularity = 0,
    this.genres = const [],
  });

  /// Spotify treats popularity as a 0–100 score; the search UI has long used
  /// 60 as its "this is a well-known artist" line, so keep that consistent.
  bool get isVerified => popularity > 60;

  factory ArtistProfile.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List?) ?? const [];
    String urlAt(int index) {
      if (images.isEmpty) return '';
      final entry = images[index] as Map?;
      return (entry?['url'] as String?) ?? '';
    }

    final followers = json['followers'];

    return ArtistProfile(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      imageUrl: urlAt(0),
      thumbnailUrl: urlAt(images.length - 1),
      followers: followers is Map
          ? ((followers['total'] as num?)?.toInt() ?? 0)
          : ((followers as num?)?.toInt() ?? 0),
      popularity: (json['popularity'] as num?)?.toInt() ?? 0,
      genres:
          ((json['genres'] as List?) ?? const []).map((g) => '$g').toList(),
    );
  }

  /// "1,234,567" — thousands separated, which is how follower counts read on
  /// every other music client.
  static String formatCount(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
