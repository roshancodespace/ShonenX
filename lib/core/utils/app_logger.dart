import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// A utility class that provides static methods for logging different types of messages.
/// Only logs messages in debug mode using the `logger` package.
class AppLogger {
  /// Internal logger instance configured with pretty printing options
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      noBoxingByDefault: true,
      methodCount: 0, // Hide method stack trace by default
      errorMethodCount: 5,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  // ANSI Colors for custom formatting
  static const String _reset = '\x1B[0m';
  static const String _bold = '\x1B[1m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _cyan = '\x1B[36m';
  static const String _blue = '\x1B[34m';

  /// Logs a debug message
  /// [message] The message to be logged
  static void d(dynamic message) {
    if (kDebugMode) _logger.d(message);
  }

  /// Logs an info message
  /// [message] The message to be logged
  static void i(dynamic message) {
    if (kDebugMode) _logger.i(message);
  }

  /// Logs a warning message
  /// [message] The message to be logged
  static void w(dynamic message) {
    if (kDebugMode) _logger.w(message);
  }

  /// Logs an error message with optional error object and stack trace
  /// [message] The error message to be logged
  /// [error] Optional error object
  /// [stackTrace] Optional stack trace
  static void e(dynamic message, [Object? error, StackTrace? stackTrace]) {
    if (error is StackTrace) {
      error = {error};
    }
    if (kDebugMode) _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a verbose message
  /// [message] The message to be logged
  static void v(dynamic message) {
    if (kDebugMode) _logger.t(message);
  }

  // --- CLI-Style Formatting Methods ---

  /// Prints a section header
  static void section(String title) {
    // Using simple print to preserve exact ANSI formatting without Logger interference
    if (kDebugMode) debugPrint('\n$_bold$_cyan=== $title ===$_reset');
  }

  /// Prints a key-value pair info
  static void infoPair(String key, dynamic value) {
    if (kDebugMode) debugPrint('$_blue$key:$_reset $value');
  }

  /// Prints a success message
  static void success(String message) {
    if (kDebugMode) debugPrint('$_green✓ $message$_reset');
  }

  /// Prints a failure/error message (simple)
  static void fail(String message) {
    if (kDebugMode) debugPrint('$_red✗ $message$_reset');
  }

  /// Prints a raw message with optional color
  static void raw(String message) {
    if (kDebugMode) debugPrint(message);
  }

  // Expose colors for external usage if needed
  static String get bold => _bold;
  static String get reset => _reset;
  static String get green => _green;
  static String get blue => _blue;
  static String get red => _red;
  static String get yellow => _yellow;
  static String get cyan => _cyan;
}
