import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/utils/responsive.dart';

/// The tracks lined up to play next, straight from the player's queue.
///
/// This renders `AudioPlayerState.queue` — the exact list playback consumes —
/// so what the user sees here is what will actually play. Tapping a row jumps
/// to it and keeps everything after it queued.
///
/// Shared by the mobile "Up next" sheet and the docked desktop queue panel.
class QueueList extends ConsumerWidget {
  /// Set on the sheet, where picking a track should also dismiss it. The
  /// docked panel stays open.
  final bool popOnTap;

  const QueueList({super.key, this.popOnTap = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);

    if (audioState.currentTrackId.isEmpty) {
      return const _QueueMessage('Play something to build a queue');
    }

    final queue = audioState.queue;

    if (queue.isEmpty) {
      // The radio queue seeds a moment after a track starts.
      if (audioState.isNextTrackLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1BD760)),
              ),
            ),
          ),
        );
      }
      return const _QueueMessage('Nothing queued');
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: queue.length,
      itemBuilder: (context, i) {
        final track = queue[i];
        return QueueTile(
          position: i + 1,
          imageUrl: track['imageUrl'] as String? ?? '',
          title: track['name'] as String? ?? '',
          artist: track['artist'] as String? ?? '',
          onTap: () {
            if (popOnTap) Navigator.pop(context);
            ref.read(audioPlayerProvider.notifier).playQueueItemAt(i);
          },
        );
      },
    );
  }
}

class _QueueMessage extends StatelessWidget {
  final String text;
  const _QueueMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white54),
      ),
    );
  }
}

class QueueTile extends StatelessWidget {
  final int position;
  final String imageUrl;
  final String title;
  final String artist;
  final VoidCallback onTap;

  const QueueTile({
    super.key,
    required this.position,
    required this.imageUrl,
    required this.title,
    required this.artist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.white.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$position',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child:
                  imageUrl.startsWith('http')
                      ? Image.network(
                        imageUrl,
                        height: 44,
                        width: 44,
                        fit: BoxFit.cover,
                        cacheWidth: context.cachePx(44),
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                      : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 44,
    width: 44,
    color: const Color(0xFF262626),
    child: const Icon(Icons.music_note, color: Colors.white38, size: 20),
  );
}
