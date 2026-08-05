import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';

/// Mute toggle plus a level slider.
///
/// The icon follows the level the way every other player does, so the button
/// doubles as the readout when the slider is too small to read at a glance.
class VolumeControl extends ConsumerWidget {
  /// Width given to the slider. Set to 0 to show just the mute button.
  final double sliderWidth;

  const VolumeControl({super.key, this.sliderWidth = 110});

  static IconData iconFor(double volume) {
    if (volume <= 0) return Icons.volume_off;
    if (volume < 0.34) return Icons.volume_mute;
    if (volume < 0.67) return Icons.volume_down;
    return Icons.volume_up;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volume = ref.watch(audioPlayerProvider.select((s) => s.volume));
    final notifier = ref.read(audioPlayerProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: notifier.toggleMute,
          icon: Icon(iconFor(volume), size: 19),
          color: const Color(0xB3FFFFFF),
          tooltip: volume <= 0 ? 'Unmute' : 'Mute',
          splashRadius: 16,
        ),
        if (sliderWidth > 0)
          SizedBox(
            width: sliderWidth,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: const Color(0x40ffffff),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                trackHeight: 3,
              ),
              child: Slider(
                value: volume,
                onChanged: notifier.setVolume,
              ),
            ),
          ),
      ],
    );
  }
}
