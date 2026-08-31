import 'dart:io';
import 'dart:math' as math;
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
      final palette = await PaletteGenerator.fromImageProvider(
        FileImage(File(originalPath)),
        maximumColorCount: 16,
        size: const Size(110, 110),
      );
      imageColorSeed = palette.dominantColor?.color.toARGB32();
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

  static Future<List<WallpaperPaletteSeed>> extractTopPaletteSeeds(
    String imagePath,
  ) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return [];

      final palette = await PaletteGenerator.fromImageProvider(
        FileImage(file),
        maximumColorCount: 32,
        size: const Size(200, 200),
      );

      final List<WallpaperPaletteSeed> seeds = [];
      final Set<int> seenArgb = {};

      void addSeed(String label, Color? color) {
        if (color == null) return;
        final argb = color.toARGB32();
        if (!seenArgb.contains(argb)) {
          final isTooClose = seeds.any(
            (s) => _colorDistance(s.color, color) < 28.0,
          );
          if (!isTooClose) {
            seenArgb.add(argb);
            seeds.add(WallpaperPaletteSeed(label: label, color: color));
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
        if (seeds.length >= 10) break;
        final argb = pc.color.toARGB32();
        if (!seenArgb.contains(argb)) {
          final isTooClose = seeds.any(
            (s) => _colorDistance(s.color, pc.color) < 28.0,
          );
          if (!isTooClose) {
            seenArgb.add(argb);
            seeds.add(
              WallpaperPaletteSeed(
                label: 'Accent $accentCount',
                color: pc.color,
              ),
            );
            accentCount++;
          }
        }
      }

      return seeds.take(10).toList();
    } catch (e) {
      debugPrint('Error extracting palette seeds: $e');
      return [];
    }
  }

  static double _colorDistance(Color c1, Color c2) {
    final r = ((c1.r * 255.0) - (c2.r * 255.0));
    final g = ((c1.g * 255.0) - (c2.g * 255.0));
    final b = ((c1.b * 255.0) - (c2.b * 255.0));
    return math.sqrt((r * r) + (g * g) + (b * b));
  }
}
