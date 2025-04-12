import 'dart:io';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class UIHelper {
  /// Toggle fullscreen mode (cross-platform)
  static Future<void> handleToggleFullscreen({
    VoidCallback? beforeCallback,
    VoidCallback? afterCallback,
    required bool isFullscreen,
  }) async {
    if (beforeCallback != null) beforeCallback();

    final isDesktop = !Platform.isAndroid && !Platform.isIOS;

    if (isFullscreen) {
      isDesktop
          ? await windowManager.setFullScreen(false)
          : await enableImmersiveMode();
    } else {
      isDesktop
          ? await windowManager.setFullScreen(true)
          : await exitImmersiveMode();
    }

    if (afterCallback != null) afterCallback();
  }

  /// Force landscape orientation (mobile only)
  static Future<void> forceLandscape() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  /// Force portrait orientation (mobile only)
  static Future<void> forcePortrait() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  /// Enable auto-rotate (allow all orientations)
  static Future<void> enableAutoRotate() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  /// Reset orientation to allow all (alias for enableAutoRotate)
  static Future<void> resetOrientation() => enableAutoRotate();

  /// Enable immersive mode (hide system UI)
  static Future<void> enableImmersiveMode() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }

  /// Exit immersive mode (show system UI)
  static Future<void> exitImmersiveMode() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  /// Hide only status bar
  static Future<void> hideStatusBarOnly() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom],
      );
    }
  }

  /// Hide only navigation bar
  static Future<void> hideNavigationBarOnly() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top],
      );
    }
  }

  /// Show all system overlays
  static Future<void> showAllOverlays() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }
}
