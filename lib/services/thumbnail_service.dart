import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:media_kit/media_kit.dart';

/// Service responsible for generating thumbnails from video frames
class ThumbnailService {
  static const int thumbnailWidth = 320;
  static const int thumbnailHeight = 180;
  static const int thumbnailQuality = 75;

  /// Generate a thumbnail from the current video frame
  /// Returns a base64-encoded JPEG image
  Future<String> generateThumbnail(Player player) async {
    log("Starting thumbnail generation");
    try {
      // Attempt screenshot capture
      log("Player state: playing=${player.state.playing}, "
          "width=${player.state.width}, height=${player.state.height}");

      if (player.state.playing &&
          player.state.width != null &&
          player.state.width! > 0 &&
          player.state.height != null &&
          player.state.height! > 0) {
        for (int attempt = 0; attempt < 2; attempt++) {
          try {
            log("Attempting screenshot capture (attempt ${attempt + 1})");
            final rawScreenshot = await player.screenshot(format: 'image/jpeg');
            if (rawScreenshot != null && rawScreenshot.isNotEmpty) {
              log("Screenshot captured: ${rawScreenshot.length} bytes");
              final result = await compute(_processThumbnail, rawScreenshot);
              if (result != null && result.isNotEmpty) {
                log("Thumbnail processed: ${result.length} bytes");
                return result;
              }
              log("Processed thumbnail is null or empty");
            } else {
              log("Screenshot is null or empty");
            }
          } catch (e, stackTrace) {
            log("Screenshot attempt failed: $e\n$stackTrace");
          }
          await Future.delayed(Duration(milliseconds: 500));
        }
      } else {
        log("Player not ready for screenshot");
      }

      // Fallback to placeholder
      log("Falling back to placeholder thumbnail");
      return await _generatePlaceholderThumbnail();
    } catch (e, stackTrace) {
      log("Critical error in thumbnail generation: $e\n$stackTrace");
      return await _generatePlaceholderThumbnail();
    }
  }

  /// Generate a placeholder thumbnail with a solid color background
  Future<String> _generatePlaceholderThumbnail() async {
    log("Generating placeholder thumbnail");
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
        log("ERROR: JPEG encoding produced empty data");
        return _generateMinimalPlaceholder();
      }

      final base64Data = base64Encode(jpegData);
      log("Placeholder thumbnail generated: ${base64Data.length} bytes");
      return base64Data;
    } catch (e, stackTrace) {
      log("Error generating placeholder: $e\n$stackTrace");
      return _generateMinimalPlaceholder();
    }
  }

  /// Generate a minimal placeholder as a last resort
  String _generateMinimalPlaceholder() {
    log("Generating minimal placeholder");
    try {
      final image = img.Image(width: thumbnailWidth, height: thumbnailHeight);
      for (int y = 0; y < thumbnailHeight; y++) {
        for (int x = 0; x < thumbnailWidth; x++) {
          image.setPixelRgba(x, y, 0, 0, 50, 255);
        }
      }
      final jpegData = img.encodeJpg(image, quality: thumbnailQuality);
      final base64Data = base64Encode(jpegData);
      log("Minimal placeholder generated: ${base64Data.length} bytes");
      return base64Data;
    } catch (e, stackTrace) {
      log("Critical error in minimal placeholder: $e\n$stackTrace");
      // Hardcoded fallback
      return 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAAAAAAAD/4QAuRXhpZgAATU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAAAAKADAAQAAAABAAAAAP/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAAAP/EABQBAQAAAAAAAAAAAAAAAAAAAAH/xAAUAQEAAAAAAAAAAAAAAAAAAAAA/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AAAD/2Q==';
    }
  }

  /// Process a raw screenshot into a thumbnail
  /// This method runs in a separate isolate via compute
  static String? _processThumbnail(Uint8List rawScreenshot) {
    log("Processing thumbnail in isolate");
    try {
      final image = img.decodeImage(rawScreenshot);
      if (image == null) {
        debugPrint("Failed to decode screenshot image");
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
        debugPrint("JPEG encoding failed");
        return null;
      }

      final base64Data = base64Encode(jpegData);
      debugPrint("Thumbnail processed: ${base64Data.length} bytes");
      return base64Data;
    } catch (e, stackTrace) {
      debugPrint("Error processing thumbnail: $e\n$stackTrace");
      return null;
    }
  }
}
