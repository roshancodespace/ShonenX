import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  // Config
  static final Logger _console = Logger(
    printer: PrettyPrinter(
      noBoxingByDefault: true,
      methodCount: 0,
      errorMethodCount: 5,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  static File? _logFile;
  static bool _isFileLoggingEnabled = false;

  // Strip colors before writing to file
  static final RegExp _ansiRegex = RegExp(r'\x1B\[[0-9;]*[mK]');

  // ANSI Colors
  static const String _reset = '\x1B[0m';
  static const String _bold = '\x1B[1m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _cyan = '\x1B[36m';
  static const String _blue = '\x1B[34m';

  /// Call in main() before runApp
  static Future<void> init() async {
    // if (!kDebugMode) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/ShonenX/app_logs.txt';

      _logFile = File(path);
      _clearLogFile(force: true);
      await _logFile!.create(recursive: true); // create dir if missing
      _isFileLoggingEnabled = true;

      _writeLine('\n\n=== SESSION START: ${DateTime.now()} ===\n');
      debugPrint('$_green✓ AppLogger ready: $path$_reset');
    } catch (e) {
      debugPrint('$_red✗ AppLogger init failed: $e$_reset');
    }
  }

  // --- Standard Logging ---

  static void d(dynamic msg) {
    if (!kDebugMode) return;
    _console.d(msg);
    _writeLine('[DEBUG] $msg');
  }

  static void i(dynamic msg) {
    if (!kDebugMode) return;
    _console.i(msg);
    _writeLine('[INFO] $msg');
  }

  static void w(dynamic msg, [Object? error, StackTrace? stack]) {
    if (!kDebugMode) return;
    _console.w(msg, error: error, stackTrace: stack);
    _writeLine('[WARN] $msg ${error ?? ""} ${stack ?? ""}');
  }

  static void e(dynamic msg, [Object? error, StackTrace? stack]) {
    if (!kDebugMode) return;
    if (error is StackTrace) error = {error};
    _console.e(msg, error: error, stackTrace: stack);
    _writeLine('[ERROR] $msg ${error ?? ""} ${stack ?? ""}');
  }

  static void v(dynamic msg) {
    if (!kDebugMode) return;
    _console.t(msg);
    _writeLine('[VERBOSE] $msg');
  }

  // --- CLI / Custom Formatting ---

  static void warning(String msg) {
    if (!kDebugMode) return;
    debugPrint('$_yellow⚠ $msg$_reset');
    _writeLine('⚠ $msg');
  }

  static void section(String title) {
    if (!kDebugMode) return;
    debugPrint('\n$_bold$_cyan=== $title ===$_reset');
    _writeLine('\n=== $title ===');
  }

  static void infoPair(String key, dynamic val) {
    if (!kDebugMode) return;
    debugPrint('$_blue$key:$_reset $val');
    _writeLine('$key: $val');
  }

  static void success(String msg) {
    if (!kDebugMode) return;
    debugPrint('$_green✓ $msg$_reset');
    _writeLine('✓ $msg');
  }

  static void fail(String msg) {
    if (!kDebugMode) return;
    debugPrint('$_red✗ $msg$_reset');
    _writeLine('✗ $msg');
  }

  static void raw(String msg) {
    if (!kDebugMode) return;
    debugPrint(msg);
    _writeLine(msg);
  }

  // --- Helpers ---

  static void _writeLine(String msg) {
    if (!_isFileLoggingEnabled || _logFile == null) return;

    try {
      final clean = msg.replaceAll(_ansiRegex, '');
      // Sync write prevents data loss during crash
      _logFile!.writeAsStringSync(
        '${DateTime.now().toIso8601String()}: $clean\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      debugPrint('Log write failed: $e');
    }
  }

  static void _clearLogFile({bool force = false}) {
    if (!force && !_isFileLoggingEnabled || _logFile == null) return;

    try {
      _logFile!.writeAsStringSync('', mode: FileMode.write);
    } catch (e) {
      debugPrint('Log clear failed: $e');
    }
  }

  // Getters
  static String get bold => _bold;
  static String get reset => _reset;
  static String get green => _green;
  static String get blue => _blue;
  static String get red => _red;
  static String get yellow => _yellow;
  static String get cyan => _cyan;
}
