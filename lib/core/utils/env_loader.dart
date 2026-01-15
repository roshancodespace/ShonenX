import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shonenx/core/utils/app_logger.dart';

class Env {
  static Map<String, String> _vars = {};
  static bool _isInitialized = false;

  static Future<void> init([String assetPath = '.env']) async {
    if (_isInitialized) return;

    try {
      final content = await rootBundle.loadString(assetPath);
      final lines = const LineSplitter().convert(content);
      final map = <String, String>{};

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

        final idx = trimmed.indexOf('=');
        if (idx == -1) continue;

        final key = trimmed.substring(0, idx).trim();
        var value = trimmed.substring(idx + 1).trim();

        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1);
        }

        map[key] = value;
      }
      
      _vars = map;
      _isInitialized = true;
      AppLogger.i('Env initialized successfully with ${_vars.length} keys');

    } catch (e) {
      AppLogger.w('Warning: Could not load env file: $e');
      _vars = {}; 
    }
  }

  static String get(String key, {String? fallback}) {
    if (!_isInitialized) {
      AppLogger.w('Warning: Env.get called before Env.init');
    }
    return _vars[key] ?? fallback ?? '';
  }
}