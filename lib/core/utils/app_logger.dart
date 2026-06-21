import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as pp;

class AppLogger {
  AppLogger._();

  static final Logger _console = Logger(
    printer: PrettyPrinter(
      noBoxingByDefault: true,
      methodCount: 0,
      errorMethodCount: 5,
      colors: false,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  static File? _logFile;
  static IOSink? _logSink;
  static bool _enabled = false;

  static final RegExp _ansiRegex = RegExp(r'\x1B\[[0-9;]*[mK]');

  // ---------- ANSI ----------
  static const _reset = '\x1B[0m';
  static const _bold = '\x1B[1m';

  static const _gray = '\x1B[90m';
  static const _blue = '\x1B[34m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';
  static const _magenta = '\x1B[35m';

  // ---------- Init ----------
  static Future<void> init() async {
    try {
      final dir = await pp.getApplicationCacheDirectory();
      final path = p.join(dir.path, 'ShonenX', 'app_logs.txt');

      _logFile = File(path);
      await _logFile!.create(recursive: true);
      
      await _logSink?.close();
      _logSink = _logFile!.openWrite(mode: FileMode.write);

      _enabled = true;

      _writeLine('=== SESSION START: ${DateTime.now()} ===');

      debugPrint('$_green✓ Logger ready: $path$_reset');
    } catch (e) {
      debugPrint('$_red✗ Logger init failed: $e$_reset');
    }
  }

  // ---------- Scope ----------
  static ScopedLogger scope(Object context) {
    final name = context is String
        ? context
        : context is Type
        ? context.toString()
        : context.runtimeType.toString();

    return ScopedLogger._(name);
  }

  // ---------- Core logging (LEVEL COLORS HERE ONLY) ----------

  static void d(String context, String msg) {
    if (!kDebugMode) return;
    final m = '$_gray$context $_gray$msg$_reset';
    _console.d(m);
    _write('[DEBUG]', '$context $msg');
  }

  static void i(String context, String msg) {
    final m = '$context $_blue$msg$_reset';
    _console.i(m);
    _write('[INFO]', '$context $msg');
  }

  static void w(String context, String msg, [Object? e, StackTrace? s]) {
    final m = '$context $_yellow$msg$_reset';
    _console.w(m, error: e, stackTrace: s);
    _write('[WARN]', '$context $msg ${e ?? ''} ${s ?? ''}');
  }

  static void s(String context, String msg) {
    final m = '$context $_green$msg$_reset';
    _console.i(m);
    _write('[SUCCESS]', '$context $msg');
  }

  static void e(String context, String msg, [Object? e, StackTrace? s]) {
    final m = '$context $_red$msg$_reset';
    _console.e(m, error: e, stackTrace: s);
    _write('[ERROR]', '$context $msg ${e ?? ''} ${s ?? ''}');
  }

  static void v(String context, String msg) {
    if (!kDebugMode) return;
    final m = '$_gray$context $_gray$msg$_reset';
    _console.t(m);
    _write('[VERBOSE]', '$context $msg');
  }

  static void raw(String msg) {
    if (!kDebugMode) return;
    debugPrint(msg);
    _write('[RAW]', msg);
  }

  // ---------- Internal ----------
  static void _write(String level, String msg) {
    if (!_enabled || _logSink == null) return;
    _writeLine('$level $msg');
  }

  static void _writeLine(String msg) {
    try {
      final clean = msg.replaceAll(_ansiRegex, '');
      _logSink!.writeln('${DateTime.now().toIso8601String()} $clean');
    } catch (e) {
      debugPrint('Log write failed: $e');
    }
  }

  // ---------- expose ----------
  static String get reset => _reset;
  static String get bold => _bold;
  static String get magenta => _magenta;
  static File? get logFile => _logFile;

  static Future<String> getLogContent() async {
    if (_logFile == null || !await _logFile!.exists()) {
      return 'No logs available.';
    }
    return await _logFile!.readAsString();
  }
}

class ScopedLogger {
  final String _context;

  const ScopedLogger._(this._context);

  String get _ctx => '${AppLogger.magenta}[$_context]${AppLogger.reset}';

  ScopedLogger child(String sub) => ScopedLogger._('$_context.$sub');

  void d(String msg) => AppLogger.d(_ctx, msg);
  void i(String msg) => AppLogger.i(_ctx, msg);
  void w(String msg, [Object? e, StackTrace? s]) =>
      AppLogger.w(_ctx, msg, e, s);
  void e(String msg, [Object? e, StackTrace? s]) =>
      AppLogger.e(_ctx, msg, e, s);
  void v(String msg) => AppLogger.v(_ctx, msg);

  void s(String msg) => AppLogger.s(_ctx, '✓ $msg');

  void fail(String msg) => AppLogger.e(_ctx, '✗ $msg');

  void warning(String msg) => AppLogger.w(_ctx, '⚠ $msg');

  void section(String title) {
    AppLogger.raw(
      '\n${AppLogger.magenta}${AppLogger.bold}=== $_context | $title ===${AppLogger.reset}',
    );
  }
}
