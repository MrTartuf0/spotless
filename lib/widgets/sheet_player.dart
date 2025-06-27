import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

class SheetPlayer extends StatefulWidget {
  const SheetPlayer({Key? key}) : super(key: key);

  @override
  State<SheetPlayer> createState() => _SheetPlayerState();
}

class _SheetPlayerState extends State<SheetPlayer> {
  bool isPlaying = false;
  double currentTime = 15.0; // 0:15
  double duration = 264.0; // 4:24
  bool isLiked = true;
  bool isShuffled = false;
  int repeatMode = 0; // 0: off, 1: all, 2: one
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });

    if (isPlaying) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentTime < duration) {
        setState(() {
          currentTime += 1;
        });
      } else {
        _stopTimer();
        setState(() {
          isPlaying = false;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatTime(double seconds) {
    int mins = (seconds / 60).floor();
    int secs = (seconds % 60).floor();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  void _onSliderChanged(double value) {
    setState(() {
      currentTime = value;
    });
  }

  void _toggleShuffle() {
    setState(() {
      isShuffled = !isShuffled;
    });
  }

  void _toggleRepeat() {
    setState(() {
      repeatMode = (repeatMode + 1) % 3;
    });
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7F1D1D), // red-900
            Color(0xFF991B1B), // red-800
            Color(0xFF7F1D1D), // red-900
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: SvgPicture.asset(
                    'assets/icons/chevron_down.svg',
                    color: Colors.white,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Blood Sugar Sex Magik (Deluxe Edition)',
                    style: TextStyle(
                      color: Colors.white,
                      letterSpacing: -0.2,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/more_options.svg',
                  color: Colors.white,
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Image.network(
                'https://i.scdn.co/image/ab67616d0000b27394d08ab63e57b0cae74e8595',
              ),
            ),
          ),

          // Song Info
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Under the Bridge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Red Hot Chili Peppers',
                        style: TextStyle(color: Colors.grey[300], fontSize: 18),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _toggleLike,
                  child: SvgPicture.asset(
                    'assets/icons/${isLiked ? 'fill_heart.svg' : 'empty_heart.svg'}',
                    color: isLiked ? Color(0xff1BD760) : Color(0x8affffff),
                  ),
                ),
              ],
            ),
          ),

          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Color(0x64ffffff),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: currentTime,
                    max: duration,
                    onChanged: _onSliderChanged,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(currentTime),
                        style: TextStyle(
                          color: Color(0xddffffff),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatTime(duration),
                        style: TextStyle(
                          color: Color(0xaaffffff),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _toggleShuffle,
                  child: SvgPicture.asset(
                    'assets/icons/shuffle.svg',
                    color: isShuffled ? Color(0xff1BD760) : Color(0x8affffff),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/previous.svg',
                  color: Color(0x8affffff),
                  height: 32,
                ),
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/forward.svg',
                  color: Colors.white,
                  height: 32,
                ),
                GestureDetector(
                  onTap: _toggleRepeat,
                  child: Stack(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/repeat.svg',
                        color:
                            repeatMode > 0
                                ? Color(0xff1BD760)
                                : Colors.grey[400],
                      ),
                      if (repeatMode == 2)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Gap(64),
        ],
      ),
    );
  }
}
