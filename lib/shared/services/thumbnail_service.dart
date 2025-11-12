import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:media_kit/media_kit.dart';
import 'package:shonenx/core/utils/app_logger.dart';

/// Service responsible for generating thumbnails from video frames
class ThumbnailService {
  static const int thumbnailWidth = 320;
  static const int thumbnailHeight = 180;
  static const int thumbnailQuality = 75;

  /// Generate a thumbnail from the current video frame
  /// Returns a base64-encoded JPEG image
  Future<String> generateThumbnail(Player player) async {
    AppLogger.d('Starting thumbnail generation');
    try {
      AppLogger.d('Player state: playing=${player.state.playing}, '
          'width=${player.state.width}, height=${player.state.height}');

      if (player.state.playing &&
          player.state.width != null &&
          player.state.width! > 0 &&
          player.state.height != null &&
          player.state.height! > 0) {
        for (int attempt = 0; attempt < 2; attempt++) {
          try {
            AppLogger.d(
                'Attempting screenshot capture (attempt ${attempt + 1})');
            final rawScreenshot = await player.screenshot(format: 'image/jpeg');
            if (rawScreenshot != null && rawScreenshot.isNotEmpty) {
              AppLogger.d('Screenshot captured: ${rawScreenshot.length} bytes');
              final result = await compute(_processThumbnail, rawScreenshot);
              if (result != null && result.isNotEmpty) {
                AppLogger.d('Thumbnail processed: ${result.length} bytes');
                return result;
              }
              AppLogger.w('Processed thumbnail is null or empty');
            } else {
              AppLogger.w('Screenshot is null or empty');
            }
          } catch (e, stackTrace) {
            AppLogger.e('Screenshot attempt failed (attempt ${attempt + 1})', e,
                stackTrace);
          }
          await Future.delayed(Duration(milliseconds: 500));
        }
      } else {
        AppLogger.w('Player not ready for screenshot');
      }

      AppLogger.d('Falling back to placeholder thumbnail');
      return await _generatePlaceholderThumbnail();
    } catch (e, stackTrace) {
      AppLogger.e('Critical error in thumbnail generation', e, stackTrace);
      return await _generatePlaceholderThumbnail();
    }
  }

  /// Generate a placeholder thumbnail with a solid color background
  Future<String> _generatePlaceholderThumbnail() async {
    AppLogger.d('Generating placeholder thumbnail');
    try {
      final image = img.Image(width: thumbnailWidth, height: thumbnailHeight);

      // Solid background (dark blue)
      for (int y = 0; y < thumbnailHeight; y++) {
        for (int x = 0; x < thumbnailWidth; x++) {
          image.setPixelRgba(x, y, 30, 20, 80, 255);
        }
      }

      // Encode to JPEG and base64
      final jpegData = img.encodeJpg(image, quality: thumbnailQuality);
      if (jpegData.isEmpty) {
        AppLogger.w('JPEG encoding produced empty data for placeholder');
        return _generateMinimalPlaceholder();
      }

      final base64Data = base64Encode(jpegData);
      AppLogger.d(
          'Placeholder thumbnail generated: ${base64Data.length} bytes');
      return base64Data;
    } catch (e, stackTrace) {
      AppLogger.e('Error generating placeholder thumbnail', e, stackTrace);
      return _generateMinimalPlaceholder();
    }
  }

  /// Generate a minimal placeholder as a last resort
  String _generateMinimalPlaceholder() {
    AppLogger.d('Generating minimal placeholder');
    try {
      final image = img.Image(width: thumbnailWidth, height: thumbnailHeight);
      for (int y = 0; y < thumbnailHeight; y++) {
        for (int x = 0; x < thumbnailWidth; x++) {
          image.setPixelRgba(x, y, 0, 0, 50, 255);
        }
      }
      final jpegData = img.encodeJpg(image, quality: thumbnailQuality);
      final base64Data = base64Encode(jpegData);
      AppLogger.d('Minimal placeholder generated: ${base64Data.length} bytes');
      return base64Data;
    } catch (e, stackTrace) {
      AppLogger.e(
          'Critical error in minimal placeholder generation', e, stackTrace);
      // Hardcoded fallback
      return 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAAAAAAAD/4QAuRXhpZgAATU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAAAAKADAAQAAAABAAAAAP/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAAAP/EABQBAQAAAAAAAAAAAAAAAAAAAAH/xAAUAQEAAAAAAAAAAAAAAAAAAAAA/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AAAD/2Q==';
    }
  }

  /// Process a raw screenshot into a thumbnail
  /// This method runs in a separate isolate via compute
  static String? _processThumbnail(Uint8List rawScreenshot) {
    AppLogger.d('Processing thumbnail in isolate');
    try {
      final image = img.decodeImage(rawScreenshot);
      if (image == null) {
        AppLogger.w('Failed to decode screenshot image');
        return null;
      }

      final resizedImage = img.copyResize(
        image,
        width: thumbnailWidth,
        height: thumbnailHeight,
        interpolation: img.Interpolation.average,
      );

      final jpegData = img.encodeJpg(resizedImage, quality: thumbnailQuality);
      if (jpegData.isEmpty) {
        AppLogger.w('JPEG encoding failed for thumbnail');
        return null;
      }

      final base64Data = base64Encode(jpegData);
      AppLogger.d('Thumbnail processed: ${base64Data.length} bytes');
      return base64Data;
    } catch (e, stackTrace) {
      AppLogger.e('Error processing thumbnail in isolate', e, stackTrace);
      return null;
    }
  }
}
