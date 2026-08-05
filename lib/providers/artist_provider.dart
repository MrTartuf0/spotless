import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/models/artist_profile.dart';
import 'package:spotACrack/services/artist_service.dart';

/// Header metadata for an artist, keyed by id so revisiting an artist is free.
final artistProfileProvider =
    FutureProvider.family<ArtistProfile, String>((ref, artistId) async {
  if (artistId.isEmpty) return const ArtistProfile(id: '', name: '');
  return ArtistService.getArtist(artistId);
});

/// Popular tracks + releases for an artist.
final artistDiscographyProvider =
    FutureProvider.family<Discography, String>((ref, artistId) async {
  if (artistId.isEmpty) return const Discography();
  return ArtistService.getArtistDiscography(artistId);
});
