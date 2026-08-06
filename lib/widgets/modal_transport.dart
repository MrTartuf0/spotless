import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/widgets/playback_shortcuts.dart';

/// Compact previous / play-pause / next row for modals that cover the player.
///
/// The lyrics and queue sheets fill the screen, taking both the mini player and
/// the desktop player bar out of reach, so they carry their own transport
/// rather than making the user close the sheet to skip a track. Tooltips name
/// the matching key, since [PlaybackShortcuts] makes all of it reachable from
/// the keyboard too.
class ModalTransport extends ConsumerWidget {
  /// Whether to draw the dismiss button on the right. Off where the sheet's
  /// own header already has one.
  final bool showClose;

  const ModalTransport({super.key, this.showClose = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioPlayerProvider);
    final notifier = ref.read(audioPlayerProvider.notifier);
    final enabled = state.currentTrackId.isNotEmpty;
    final hasPrevious = state.index > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Balances the close button so the transport stays centred.
          if (showClose) const SizedBox(width: 48),
          const Spacer(),
          _TransportButton(
            icon: Icons.skip_previous,
            tooltip: 'Previous (${shortcutHint(context, '←')})',
            size: 30,
            color: hasPrevious ? Colors.white : const Color(0x4DFFFFFF),
            onTap: hasPrevious ? notifier.playPreviousTrack : null,
          ),
          const SizedBox(width: 12),
          _PlayPauseButton(
            isPlaying: state.isPlaying,
            isLoading: state.isLoading,
            enabled: enabled,
            onTap: notifier.togglePlayPause,
          ),
          const SizedBox(width: 12),
          _TransportButton(
            icon: Icons.skip_next,
            tooltip: 'Next (${shortcutHint(context, '→')})',
            size: 30,
            color: enabled ? Colors.white : const Color(0x4DFFFFFF),
            onTap: enabled ? notifier.playNextTrack : null,
          ),
          const Spacer(),
          if (showClose)
            _TransportButton(
              icon: Icons.keyboard_arrow_down,
              tooltip: 'Close (Esc)',
              size: 28,
              color: const Color(0xB3FFFFFF),
              onTap: () => Navigator.of(context).maybePop(),
            ),
        ],
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isPlaying ? 'Pause (Space)' : 'Play (Space)',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0x33FFFFFF),
            shape: BoxShape.circle,
          ),
          child:
              isLoading
                  ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                  : Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 26,
                  ),
        ),
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final double size;
  final Color color;
  final VoidCallback? onTap;

  const _TransportButton({
    required this.icon,
    required this.tooltip,
    required this.size,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}
