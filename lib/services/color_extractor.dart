import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';

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

      // Check contrast with white text first
      double contrastRatio = _calculateContrastRatio(color, Colors.white);
      if (contrastRatio < 4.5) {
        score *= 0.1; // Heavily penalize poor contrast
        continue;
      }

      // Boost score for good contrast
      if (contrastRatio >= 7.0) {
        score += 150;
      } else if (contrastRatio >= 4.5) {
        score += 100;
      }

      // Avoid problematic colors for text readability
      // Penalize yellows, light greens, and other bright colors
      if (hsl.hue >= 45 && hsl.hue <= 65 && hsl.saturation > 0.4) {
        // Yellow range
        score *= 0.2;
      } else if (hsl.hue >= 75 && hsl.hue <= 150 && hsl.lightness > 0.4) {
        // Light green range
        score *= 0.3;
      } else if (hsl.hue >= 30 && hsl.hue <= 90 && hsl.lightness > 0.5) {
        // Bright yellow-green
        score *= 0.2;
      }

      // Prefer colors with good saturation (0.3 to 0.8)
      if (hsl.saturation >= 0.3 && hsl.saturation <= 0.8) {
        score += hsl.saturation * 80;
      } else if (hsl.saturation < 0.3) {
        score += hsl.saturation * 30;
      }

      // Prefer darker colors for better contrast with white text
      if (hsl.lightness >= 0.15 && hsl.lightness <= 0.5) {
        score += (1 - hsl.lightness) * 70;
      }

      // Penalize very bright or very dark colors
      if (hsl.lightness < 0.08 || hsl.lightness > 0.6) {
        score *= 0.4;
      }

      // Boost darker reds, browns, purples, and blues (typical good background colors)
      if ((hsl.hue >= 0 && hsl.hue <= 30) ||
          (hsl.hue >= 330 && hsl.hue <= 360)) {
        // Reds
        score += 50;
      } else if (hsl.hue >= 240 && hsl.hue <= 300) {
        // Blues and purples
        score += 40;
      } else if (hsl.hue >= 15 && hsl.hue <= 45 && hsl.lightness < 0.4) {
        // Browns
        score += 45;
      }

      if (score > bestScore) {
        bestScore = score;
        bestColor = color;
      }
    }

    return bestColor;
  }

  // Calculate WCAG contrast ratio between two colors
  static double _calculateContrastRatio(Color color1, Color color2) {
    double luminance1 = _calculateLuminance(color1);
    double luminance2 = _calculateLuminance(color2);

    double lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    double darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  // Calculate relative luminance of a color
  static double _calculateLuminance(Color color) {
    double r = color.red / 255.0;
    double g = color.green / 255.0;
    double b = color.blue / 255.0;

    r = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4).toDouble();
    g = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4).toDouble();
    b = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
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
