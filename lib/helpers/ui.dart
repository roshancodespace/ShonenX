import 'dart:io';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class UIHelper {
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
          : await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      isDesktop
          ? await windowManager.setFullScreen(true)
          : await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (afterCallback != null) afterCallback();
  }
}
