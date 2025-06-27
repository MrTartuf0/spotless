import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';

// Color extractor class optimized for album artwork
class ColorExtractor {
  static Future<Color> extractDominantColor(ImageProvider imageProvider) async {
    try {
      final ImageStream stream = imageProvider.resolve(
        const ImageConfiguration(),
      );
      final Completer<ui.Image> completer = Completer();

      late ImageStreamListener listener;
      listener = ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
        stream.removeListener(listener);
      });

      stream.addListener(listener);
      final ui.Image image = await completer.future;

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return const Color(0xff491d18);

      final Uint8List pixels = byteData.buffer.asUint8List();
      final List<Color> dominantColors = _extractDominantColors(
        pixels,
        image.width,
        image.height,
      );
      final Color primaryColor = _selectBestBackgroundColor(dominantColors);

      return _adjustForBottomPlayer(primaryColor);
    } catch (e) {
      return const Color(0xff491d18); // Fallback color
    }
  }

  static List<Color> _extractDominantColors(
    Uint8List pixels,
    int width,
    int height,
  ) {
    final Map<String, ColorInfo> colorMap = {};

    // Sample pixels efficiently
    for (int i = 0; i < pixels.length; i += 12) {
      // Sample every 3rd pixel
      if (i + 3 >= pixels.length) break;

      final int r = pixels[i];
      final int g = pixels[i + 1];
      final int b = pixels[i + 2];
      final int a = pixels[i + 3];

      // Skip transparent, very light, or very dark pixels
      if (a < 200 || (r + g + b) < 60 || (r + g + b) > 650) continue;

      // Quantize colors to group similar shades
      final int qR = (r / 32).floor() * 32;
      final int qG = (g / 32).floor() * 32;
      final int qB = (b / 32).floor() * 32;

      final String key = '$qR-$qG-$qB';

      if (colorMap.containsKey(key)) {
        colorMap[key]!.count++;
      } else {
        colorMap[key] = ColorInfo(Color.fromARGB(255, qR, qG, qB), 1);
      }
    }

    // Sort by frequency and return top colors
    final List<ColorInfo> sortedColors =
        colorMap.values.toList()..sort((a, b) => b.count.compareTo(a.count));

    return sortedColors.take(6).map((info) => info.color).toList();
  }

  static Color _selectBestBackgroundColor(List<Color> colors) {
    if (colors.isEmpty) return const Color(0xff491d18);

    Color bestColor = colors.first;
    double bestScore = 0;

    for (final Color color in colors) {
      final HSLColor hsl = HSLColor.fromColor(color);

      double score = 0;

      // Prefer colors with good saturation (0.3 to 0.8)
      if (hsl.saturation >= 0.3 && hsl.saturation <= 0.8) {
        score += hsl.saturation * 100;
      } else if (hsl.saturation < 0.3) {
        score += hsl.saturation * 40;
      }

      // Prefer darker colors for better contrast with white text
      if (hsl.lightness >= 0.2 && hsl.lightness <= 0.6) {
        score += (1 - hsl.lightness) * 80;
      }

      // Penalize very bright or very dark colors
      if (hsl.lightness < 0.1 || hsl.lightness > 0.7) {
        score *= 0.3;
      }

      if (score > bestScore) {
        bestScore = score;
        bestColor = color;
      }
    }

    return bestColor;
  }

  static Color _adjustForBottomPlayer(Color color) {
    final HSLColor hsl = HSLColor.fromColor(color);

    // Increase saturation to match Spotify's more vibrant colors
    double newSaturation = (hsl.saturation * 0.9).clamp(0.4, 0.95);

    // Fine-tune lightness to match Spotify's darkness level
    double newLightness = hsl.lightness;
    if (newLightness > 0.35) {
      newLightness = newLightness * 0.6;
    }
    newLightness = newLightness.clamp(0.12, 0.35);

    return hsl
        .withSaturation(newSaturation)
        .withLightness(newLightness)
        .toColor();
  }
}

class ColorInfo {
  final Color color;
  int count;

  ColorInfo(this.color, this.count);
}
