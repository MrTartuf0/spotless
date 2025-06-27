import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';

import 'package:rick_spot/services/color_extractor.dart';

class BottomPlayer extends StatefulWidget {
  const BottomPlayer({super.key});

  @override
  State<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends State<BottomPlayer> {
  Color containerColor = const Color(0xff491d18); // Default color
  bool isLoadingColor = true;

  // Current track data - you can make these dynamic later
  final String currentTrackImage =
      'https://i.scdn.co/image/ab67616d00001e02153d79816d853f2694b2cc70';
  final String currentTrackTitle = 'Under the bridge';
  final String currentTrackArtist = 'Red Hot Chili Peppers';

  @override
  void initState() {
    super.initState();
    _extractColorFromCurrentTrack();
  }

  Future<void> _extractColorFromCurrentTrack() async {
    try {
      final Color extractedColor = await ColorExtractor.extractDominantColor(
        NetworkImage(currentTrackImage),
      );

      if (mounted) {
        setState(() {
          containerColor = extractedColor;
          isLoadingColor = false;
        });
      }
    } catch (e) {
      print('Error extracting color: $e');
      if (mounted) {
        setState(() {
          isLoadingColor = false;
        });
      }
    }
  }

  // Call this method when track changes
  Future<void> updateTrack(String imageUrl, String title, String artist) async {
    setState(() {
      isLoadingColor = true;
    });

    try {
      final Color extractedColor = await ColorExtractor.extractDominantColor(
        NetworkImage(imageUrl),
      );

      if (mounted) {
        setState(() {
          containerColor = extractedColor;
          isLoadingColor = false;
        });
      }
    } catch (e) {
      print('Error extracting color: $e');
      if (mounted) {
        setState(() {
          isLoadingColor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 70),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            height: 56,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.network(
                      currentTrackImage,
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentTrackTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                            height: 1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Gap(4),
                        Text(
                          currentTrackArtist,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/fill_heart.svg',
                    color: const Color(0xff1BD760),
                  ),
                  const Gap(24),
                  SvgPicture.asset(
                    'assets/icons/play.svg',
                    color: Colors.white,
                  ),
                  const Gap(8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
