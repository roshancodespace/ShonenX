import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';

class WallpaperPaletteSeed {
  final String label;
  final Color color;

  const WallpaperPaletteSeed({required this.label, required this.color});
}

class WallpaperProcessor {
  // In-memory cache to ensure instant tab switches and avoid redundant computations
  static final Map<String, List<WallpaperPaletteSeed>> _cachedSeeds = {};

  static List<WallpaperPaletteSeed>? getCachedPaletteSeeds(String imagePath) {
    return _cachedSeeds[imagePath];
  }

  static void clearCache() {
    _cachedSeeds.clear();
  }

  static Future<Directory> _getThemeDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final themeDirPath = '${docDir.path}/ShonenX/Theme';
    final themeDir = Directory(themeDirPath);

    if (!await themeDir.exists()) {
      await themeDir.create(recursive: true);
    }
    return themeDir;
  }

  static Future<String> saveOriginalWallpaper(String sourcePath) async {
    clearCache();
    final themeDir = await _getThemeDirectory();

    final files = themeDir.listSync();
    for (var file in files) {
      if (file is File && file.path.contains('original_wallpaper_')) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    final ext = sourcePath.split('.').last.toLowerCase();
    final safeExt = ['png', 'jpg', 'jpeg', 'webp'].contains(ext) ? ext : 'png';
    final newPath =
        '${themeDir.path}/original_wallpaper_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    await File(sourcePath).copy(newPath);
    return newPath;
  }

  static Future<({String processedPath, int? imageColorSeed})?> process({
    required String originalPath,
    required double blurSigma,
    required double saturation,
    required double brightness,
  }) async {
    int? imageColorSeed;

    try {
      final seeds = await extractTopPaletteSeeds(originalPath);
      if (seeds.isNotEmpty) {
        imageColorSeed = seeds.first.color.toARGB32();
      }
    } catch (e) {
      debugPrint('Error generating palette: $e');
    }

    final themeDir = await _getThemeDirectory();

    final files = themeDir.listSync();
    for (var file in files) {
      if (file is File && file.path.contains('blurred_wallpaper_')) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    if (blurSigma <= 0.0 && saturation == 1.0 && brightness == 1.0) {
      return (processedPath: originalPath, imageColorSeed: imageColorSeed);
    }

    try {
      final fileName =
          'blurred_wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';
      final outputPath = '${themeDir.path}/$fileName';

      final data = await File(originalPath).readAsBytes();

      var codec = await ui.instantiateImageCodec(data);
      var frame = await codec.getNextFrame();
      var originalImage = frame.image;

      var width = originalImage.width;
      var height = originalImage.height;

      const maxDimension = 1080;
      if (width > maxDimension || height > maxDimension) {
        final ratio = width / height;
        final int targetWidth;
        final int targetHeight;
        if (width > height) {
          targetWidth = maxDimension;
          targetHeight = (maxDimension / ratio).round();
        } else {
          targetHeight = maxDimension;
          targetWidth = (maxDimension * ratio).round();
        }
        originalImage.dispose();

        codec = await ui.instantiateImageCodec(
          data,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
        );
        frame = await codec.getNextFrame();
        originalImage = frame.image;
        width = originalImage.width;
        height = originalImage.height;
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      final paint = ui.Paint();
      if (blurSigma > 0.0) {
        paint.imageFilter = ui.ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        );
      }

      final double r = 0.2126;
      final double g = 0.7152;
      final double b = 0.0722;
      final double invS = 1.0 - saturation;
      final double R = r * invS;
      final double G = g * invS;
      final double B = b * invS;

      paint.colorFilter = ui.ColorFilter.matrix([
        (R + saturation) * brightness,
        G * brightness,
        B * brightness,
        0,
        0,
        R * brightness,
        (G + saturation) * brightness,
        B * brightness,
        0,
        0,
        R * brightness,
        G * brightness,
        (B + saturation) * brightness,
        0,
        0,
        0,
        0,
        0,
        1.0,
        0,
      ]);

      canvas.drawImage(originalImage, ui.Offset.zero, paint);

      final picture = recorder.endRecording();
      final blurredImage = await picture.toImage(width, height);

      final byteData = await blurredImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        throw Exception('Failed to generate PNG byte data.');
      }
      final bytes = byteData.buffer.asUint8List();

      final blurredFile = File(outputPath);
      await blurredFile.writeAsBytes(bytes);

      originalImage.dispose();
      blurredImage.dispose();

      return (processedPath: outputPath, imageColorSeed: imageColorSeed);
    } catch (e, stack) {
      debugPrint('Error processing background image: $e\n$stack');
      return (processedPath: originalPath, imageColorSeed: imageColorSeed);
    }
  }

  /// Extracts top palette seeds using hardware downsampling (<2ms) and
  /// executing the heavy color quantization entirely in a background isolate.
  static Future<List<WallpaperPaletteSeed>> extractTopPaletteSeeds(
    String imagePath,
  ) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return [];

      final lastMod = (await file.lastModified()).millisecondsSinceEpoch;
      final cacheKey = '$imagePath:$lastMod';
      final cached = _cachedSeeds[cacheKey] ?? _cachedSeeds[imagePath];
      if (cached != null) return cached;

      final fileBytes = await file.readAsBytes();
      if (fileBytes.isEmpty) return [];

      final codec = await ui.instantiateImageCodec(
        fileBytes,
        targetWidth: 100,
        targetHeight: 100,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        image.dispose();
        return [];
      }

      final rawBytes = byteData.buffer.asUint8List();
      final width = image.width;
      final height = image.height;
      image.dispose();

      final rawSeeds = await Isolate.run(() async {
        final encoded = EncodedImage(
          ByteData.view(rawBytes.buffer),
          width: width,
          height: height,
        );

        final palette = await PaletteGenerator.fromByteData(
          encoded,
          maximumColorCount: 32,
        );

        final List<({String label, int argb})> result = [];
        final Set<int> seenArgb = {};

        void addSeed(String label, Color? color) {
          if (color == null) return;
          final argb = color.toARGB32();
          if (!seenArgb.contains(argb)) {
            final isTooClose = result.any(
              (s) => _colorDistanceArgb(s.argb, argb) < 28.0,
            );
            if (!isTooClose) {
              seenArgb.add(argb);
              result.add((label: label, argb: argb));
            }
          }
        }

        addSeed('Dominant', palette.dominantColor?.color);
        addSeed('Vibrant', palette.vibrantColor?.color);
        addSeed('Light Vibrant', palette.lightVibrantColor?.color);
        addSeed('Dark Vibrant', palette.darkVibrantColor?.color);
        addSeed('Muted', palette.mutedColor?.color);
        addSeed('Light Muted', palette.lightMutedColor?.color);
        addSeed('Dark Muted', palette.darkMutedColor?.color);

        final sortedByPop = List<PaletteColor>.from(palette.paletteColors)
          ..sort((a, b) => b.population.compareTo(a.population));

        int accentCount = 1;
        for (final pc in sortedByPop) {
          if (result.length >= 10) break;
          final argb = pc.color.toARGB32();
          if (!seenArgb.contains(argb)) {
            final isTooClose = result.any(
              (s) => _colorDistanceArgb(s.argb, argb) < 28.0,
            );
            if (!isTooClose) {
              seenArgb.add(argb);
              result.add((label: 'Accent $accentCount', argb: argb));
              accentCount++;
            }
          }
        }

        return result.take(10).toList();
      });

      final seeds = rawSeeds
          .map(
            (s) => WallpaperPaletteSeed(label: s.label, color: Color(s.argb)),
          )
          .toList();

      _cachedSeeds[cacheKey] = seeds;
      _cachedSeeds[imagePath] = seeds;
      return seeds;
    } catch (e) {
      debugPrint('Error extracting palette seeds: $e');
      return [];
    }
  }

  static double _colorDistanceArgb(int argb1, int argb2) {
    final r1 = (argb1 >> 16) & 0xFF;
    final g1 = (argb1 >> 8) & 0xFF;
    final b1 = argb1 & 0xFF;

    final r2 = (argb2 >> 16) & 0xFF;
    final g2 = (argb2 >> 8) & 0xFF;
    final b2 = argb2 & 0xFF;

    final dr = r1 - r2;
    final dg = g1 - g2;
    final db = b1 - b2;
    return math.sqrt((dr * dr) + (dg * dg) + (db * db));
  }
}
