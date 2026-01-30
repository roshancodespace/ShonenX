import 'dart:io';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class UIHelper {
  static bool _isFullscreen = false;
  static bool get _isDesktop => !Platform.isAndroid && !Platform.isIOS;

  /// Toggle fullscreen mode (cross-platform)
  static Future<void> handleToggleFullscreen({
    VoidCallback? beforeCallback,
    VoidCallback? afterCallback,
  }) async {
    if (beforeCallback != null) beforeCallback();

    if (_isFullscreen) {
      _isDesktop
          ? await windowManager.setFullScreen(false)
          : await exitImmersiveMode();
      _isFullscreen = false;
    } else {
      _isDesktop
          ? await windowManager.setFullScreen(true)
          : await enableImmersiveMode();
      _isFullscreen = true;
    }

    if (afterCallback != null) afterCallback();
  }

  /// Force landscape orientation (mobile only)
  static Future<void> forceLandscape() async {
    if (!_isDesktop) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  /// Force portrait orientation (mobile only)
  static Future<void> forcePortrait() async {
    if (!_isDesktop) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  /// Enable auto-rotate (allow all orientations)
  static Future<void> enableAutoRotate() async {
    if (!_isDesktop) {
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
    if (!_isDesktop) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _isFullscreen = true;
    }
  }

  /// Exit immersive mode (show system UI)
  static Future<void> exitImmersiveMode() async {
    if (!_isDesktop) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _isFullscreen = false;
    }
  }

  /// Hide only status bar
  static Future<void> hideStatusBarOnly() async {
    if (!_isDesktop) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom],
      );
      _isFullscreen = true;
    }
  }

  /// Hide only navigation bar
  static Future<void> hideNavigationBarOnly() async {
    if (!_isDesktop) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top],
      );
      _isFullscreen = true;
    }
  }

  /// Show all system overlays
  static Future<void> showAllOverlays() async {
    if (!_isDesktop) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      _isFullscreen = true;
    }
  }
}
