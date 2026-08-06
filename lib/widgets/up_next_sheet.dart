import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/widgets/modal_transport.dart';
import 'package:spotACrack/widgets/playback_shortcuts.dart';
import 'package:spotACrack/widgets/queue_list.dart';

/// Bottom-sheet wrapper around [QueueList], used on narrow windows. Wide ones
/// dock the same list beside the content instead.
class UpNextSheet extends ConsumerWidget {
  const UpNextSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);

    return PlaybackShortcuts(
      dismissible: true,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF181818),
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetGrabber(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Up next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (audioState.currentTrackTitle.isNotEmpty)
                    Flexible(
                      child: Text(
                        'from ${audioState.currentTrackTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Flexible(child: QueueList(popOnTap: true)),
            // The queue can cover the whole screen, so it carries its own
            // transport and dismiss rather than stranding the player.
            const ModalTransport(),
          ],
        ),
      ),
    );
  }
}

/// Grab bar that tells the user the sheet can be dragged away.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
