import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotACrack/providers/artist_provider.dart';
import 'package:spotACrack/providers/history_provider.dart';

/// Circular artist card for the Home shelf and the library's Artists filter.
///
/// Artists picked up from playback only come with an id and a name, so this
/// resolves the artwork itself and writes it back to history — the next time
/// the shelf is built, the image is already there.
class ArtistAvatarCard extends ConsumerWidget {
  final String artistId;
  final String name;
  final String imageUrl;
  final double size;

  const ArtistAvatarCard({
    super.key,
    required this.artistId,
    required this.name,
    this.imageUrl = '',
    this.size = 148,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var image = imageUrl;
    var label = name;
    var verified = false;

    // Only artists we already have artwork for skip the lookup; the rest were
    // picked up from a track or a search hit that carried just an id.
    if (image.isEmpty && artistId.isNotEmpty) {
      final profile = ref.watch(artistProfileProvider(artistId)).valueOrNull;
      if (profile != null) {
        image = profile.imageUrl;
        verified = profile.isVerified;
        if (label.isEmpty) label = profile.name;
        if (image.isNotEmpty) {
          // Cache it for next time. Fire-and-forget; the write is a no-op
          // once the row already has this url.
          ref.read(historyServiceProvider).updateArtistImage(artistId, image);
        }
      }
    }

    return InkWell(
      onTap: artistId.isEmpty
          ? null
          : () => context.push(
                '/artist/$artistId'
                '?name=${Uri.encodeComponent(label)}'
                '&image=${Uri.encodeComponent(image)}',
              ),
      borderRadius: BorderRadius.circular(size),
      child: SizedBox(
        width: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: image.startsWith('http')
                  ? Image.network(
                      image,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (verified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 13, color: Color(0xff4CB3FF)),
                ],
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Artist',
              style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: size,
    height: size,
    color: const Color(0xFF262626),
    child: Icon(Icons.person, color: Colors.white38, size: size * 0.4),
  );
}
