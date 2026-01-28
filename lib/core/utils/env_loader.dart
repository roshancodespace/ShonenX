import 'package:shonenx/core/utils/app_logger.dart';

class Env {
  static bool _isLogged = false;

  static void init() {
    if (_isLogged) return;
    
    if (get('API_URL').isEmpty) {
      AppLogger.w('Warning: API_URL is missing from environment defines.');
    } else {
      AppLogger.i('Env initialized successfully via dart-define.');
    }
    
    _isLogged = true;
  }

  static String get(String key, {String? fallback}) {
    final value = String.fromEnvironment(key);
    
    if (value.isEmpty) {
      return fallback ?? '';
    }
    
    return value;
  }

  static bool getBool(String key, {bool fallback = false}) {
    return bool.fromEnvironment(key, defaultValue: fallback);
  }
}