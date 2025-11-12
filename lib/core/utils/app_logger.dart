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
    if (kDebugMode) _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a verbose message
  /// [message] The message to be logged
  static void v(dynamic message) {
    if (kDebugMode) _logger.t(message);
  }
}
