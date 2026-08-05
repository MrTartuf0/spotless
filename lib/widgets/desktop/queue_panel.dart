import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/providers/ui_provider.dart';
import 'package:spotACrack/widgets/queue_list.dart';

/// Queue docked beside the content on wide windows, in place of the sheet the
/// phone layout opens.
class QueuePanel extends ConsumerWidget {
  const QueuePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(audioPlayerProvider).currentTrackTitle;

    return Container(
      width: 320,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                const Text(
                  'Queue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () =>
                      ref.read(queuePanelOpenProvider.notifier).state = false,
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.white70,
                  tooltip: 'Hide queue',
                  splashRadius: 16,
                ),
              ],
            ),
          ),
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'from $title',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12.5,
                ),
              ),
            ),
          const Expanded(child: QueueList()),
        ],
      ),
    );
  }
}
