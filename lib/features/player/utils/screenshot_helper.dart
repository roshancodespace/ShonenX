import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ScreenshotHelper {
  /// Captures a screenshot and either saves (desktop) or shares (mobile) it.
  ///
  /// Returns a record with [success] and a user-facing [message].
  static Future<({bool success, String message})> captureAndShare(
    ScreenshotController controller, {
    String? mediaTitle,
  }) async {
    try {
      final image = await controller.capture(pixelRatio: 1.5);
      if (image == null) {
        return (success: false, message: 'Failed to capture screenshot.');
      }

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return await _saveToDesktop(image);
      } else {
        return await _shareOnMobile(image, mediaTitle: mediaTitle);
      }
    } catch (e) {
      return (success: false, message: 'Screenshot error: $e');
    }
  }

  /// Desktop: show a save-file picker and write the PNG.
  static Future<({bool success, String message})> _saveToDesktop(
    List<int> image,
  ) async {
    final now = DateTime.now();
    final timestamp =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final defaultFileName = 'ShonenX_$timestamp.png';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Screenshot',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['png'],
    );

    if (savePath == null) {
      return (success: false, message: 'Save cancelled');
    }

    final file = File(savePath);
    await file.writeAsBytes(image);
    return (success: true, message: 'Screenshot saved to ${file.path}');
  }

  /// Mobile: write to temp dir and open the share sheet.
  static Future<({bool success, String message})> _shareOnMobile(
    List<int> image, {
    String? mediaTitle,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Screenshot from ${mediaTitle ?? "ShonenX"}',
      ),
    );
    return (success: true, message: 'Screenshot captured');
  }
}
