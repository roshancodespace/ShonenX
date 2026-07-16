import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';

class WallpaperProcessor {
  static Future<({String processedPath, int? imageColorSeed})?> process({
    required String originalPath,
    required double blurSigma,
    required double saturation,
    required double brightness,
    String? currentOriginalPath,
    String? currentProcessedPath,
  }) async {
    int? imageColorSeed;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        FileImage(File(originalPath)),
        maximumColorCount: 16,
        size: const Size(110, 110),
      );
      imageColorSeed = palette.dominantColor?.color.value;
    } catch (e) {
      debugPrint('Error generating palette: $e');
    }

    void cleanOldFiles() async {
      if (currentProcessedPath != null &&
          currentProcessedPath != originalPath) {
        try {
          final oldFile = File(currentProcessedPath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (_) {}
      }
      if (currentOriginalPath != null && currentOriginalPath != originalPath) {
        try {
          final oldFile = File(currentOriginalPath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (_) {}
      }
    }

    if (blurSigma <= 0.0 && saturation == 1.0 && brightness == 1.0) {
      cleanOldFiles();
      return (processedPath: originalPath, imageColorSeed: imageColorSeed);
    }

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final fileName =
          'blurred_wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';
      final outputPath = '${docDir.path}/$fileName';

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

      cleanOldFiles();

      return (processedPath: outputPath, imageColorSeed: imageColorSeed);
    } catch (e, stack) {
      debugPrint('Error processing background image: $e\n$stack');
      return (processedPath: originalPath, imageColorSeed: imageColorSeed);
    }
  }
}
