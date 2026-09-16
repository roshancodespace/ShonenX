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
  static Completer<void>? _initCompleter;

  static int _currentLogBytes = 0;
  static const int _maxLogSizeBytes = 2 * 1024 * 1024;
  static bool _isRotating = false;

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
    if (_enabled && _logSink != null) return;
    if (_initCompleter != null) return _initCompleter!.future;

    final completer = Completer<void>();
    _initCompleter = completer;

    try {
      final dir =
          ((Platform.isAndroid || Platform.isIOS)
              ? await pp.getExternalStorageDirectory()
              : null) ??
          await pp.getApplicationDocumentsDirectory();
      final path = p.join(dir.path, 'ShonenX', 'app_logs.txt');

      final file = File(path);
      await file.create(recursive: true);

      if (await file.exists()) {
        final length = await file.length();
        if (length >= _maxLogSizeBytes) {
          await _rotateFile(file);
        } else {
          _currentLogBytes = length;
        }
      }

      if (_logSink != null) {
        final oldSink = _logSink;
        _logSink = null;
        await oldSink!.flush();
        await oldSink.close();
      }

      _logFile = file;
      _logSink = file.openWrite(mode: FileMode.append);
      _enabled = true;

      _writeLine('=== SESSION START: ${DateTime.now()} ===');

      debugPrint('$_green✓ Logger ready: $path$_reset');
      completer.complete();
    } catch (e) {
      _enabled = false;
      _logSink = null;
      debugPrint('$_red✗ Logger init failed: $e$_reset');
      completer.complete();
    } finally {
      _initCompleter = null;
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

  // ---------- Core logging ----------

  static void d(String context, String msg) {
    if (!kDebugMode) return;
    _console.d('$_gray$context $_gray$msg$_reset');
    _write('[DEBUG]', context, msg);
  }

  static void i(String context, String msg) {
    _console.i('$context $_blue$msg$_reset');
    _write('[INFO]', context, msg);
  }

  static void w(String context, String msg, [Object? e, StackTrace? s]) {
    _console.w('$context $_yellow$msg$_reset', error: e, stackTrace: s);
    _write('[WARN]', context, msg, e, s);
  }

  static void s(String context, String msg) {
    _console.i('$context $_green$msg$_reset');
    _write('[SUCCESS]', context, msg);
  }

  static void e(String context, String msg, [Object? e, StackTrace? s]) {
    _console.e('$context $_red$msg$_reset', error: e, stackTrace: s);
    _write('[ERROR]', context, msg, e, s);
  }

  static void v(String context, String msg) {
    if (!kDebugMode) return;
    _console.t('$_gray$context $_gray$msg$_reset');
    _write('[VERBOSE]', context, msg);
  }

  static void raw(String msg, {String? cleanMsg}) {
    if (!kDebugMode) return;
    debugPrint(msg);
    if (_enabled && _logSink != null) {
      _writeLine('[RAW] ${cleanMsg ?? _stripAnsi(msg)}');
    }
  }

  // ---------- Internal ----------

  static void _log({
    required String levelTag,
    required String consoleContext,
    required String fileContext,
    required String msg,
    required String colorCode,
    Object? error,
    StackTrace? stackTrace,
    bool isVerboseOrDebug = false,
  }) {
    if (isVerboseOrDebug && !kDebugMode) return;

    if (levelTag == '[DEBUG]') {
      _console.d('$_gray$consoleContext $_gray$msg$_reset');
    } else if (levelTag == '[VERBOSE]') {
      _console.t('$_gray$consoleContext $_gray$msg$_reset');
    } else if (levelTag == '[WARN]') {
      _console.w(
        '$consoleContext $colorCode$msg$_reset',
        error: error,
        stackTrace: stackTrace,
      );
    } else if (levelTag == '[ERROR]') {
      _console.e(
        '$consoleContext $colorCode$msg$_reset',
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      _console.i('$consoleContext $colorCode$msg$_reset');
    }

    if (_enabled && _logSink != null) {
      final text = _buildFileMessage(fileContext, msg, error, stackTrace);
      _writeLine('$levelTag $text');
    }
  }

  static void _write(
    String level,
    String context,
    String msg, [
    Object? e,
    StackTrace? s,
  ]) {
    if (!_enabled || _logSink == null) return;
    final cleanContext = _stripAnsi(context);
    final text = _buildFileMessage(cleanContext, msg, e, s);
    _writeLine('$level $text');
  }

  static String _buildFileMessage(
    String context,
    String msg, [
    Object? e,
    StackTrace? s,
  ]) {
    final cleanMsg = _stripAnsi(msg);
    if (e == null && s == null) {
      return '$context $cleanMsg';
    }
    final buffer = StringBuffer(context)
      ..write(' ')
      ..write(cleanMsg);
    if (e != null) {
      buffer
        ..write(' ')
        ..write(e);
    }
    if (s != null) {
      buffer
        ..write(' ')
        ..write(s);
    }
    return buffer.toString();
  }

  static void _writeLine(String line) {
    final sink = _logSink;
    if (sink == null) return;

    try {
      final formatted = '${DateTime.now().toIso8601String()} $line';
      sink.writeln(formatted);
      _currentLogBytes += formatted.length + 1;

      if (_currentLogBytes >= _maxLogSizeBytes && !_isRotating) {
        _rotateRuntime();
      }
    } catch (e) {
      debugPrint('Log write failed: $e');
    }
  }

  static void _rotateRuntime() {
    _isRotating = true;
    Future<void>.microtask(() async {
      try {
        final sink = _logSink;
        final file = _logFile;
        if (file == null) return;

        _logSink = null;
        if (sink != null) {
          await sink.flush();
          await sink.close();
        }

        await _rotateFile(file);
        _logSink = file.openWrite(mode: FileMode.write);
        _currentLogBytes = 0;
        _writeLine('=== LOG ROTATED: ${DateTime.now()} ===');
      } catch (e) {
        debugPrint('Runtime log rotation failed: $e');
      } finally {
        _isRotating = false;
      }
    });
  }

  static Future<void> _rotateFile(File file) async {
    try {
      final oldFile = File('${file.path}.old');
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
      await file.rename(oldFile.path);
      _currentLogBytes = 0;
    } catch (e) {
      try {
        await file.writeAsString('');
        _currentLogBytes = 0;
      } catch (_) {}
    }
  }

  static String _stripAnsi(String text) {
    return text.contains('\x1B') ? text.replaceAll(_ansiRegex, '') : text;
  }

  // ---------- Expose ----------
  static String get reset => _reset;
  static String get bold => _bold;
  static String get magenta => _magenta;
  static File? get logFile => _logFile;

  static Future<String> getLogContent() async {
    try {
      if (_logSink != null) {
        await _logSink!.flush();
      }
      if (_logFile == null || !await _logFile!.exists()) {
        return 'No logs available.';
      }
      final content = await _logFile!.readAsString();
      return content.trim().isEmpty ? 'No logs available.' : content;
    } catch (e) {
      return 'No logs available.';
    }
  }

  static Future<void> clearLogs() async {
    try {
      final sink = _logSink;
      _logSink = null;
      if (sink != null) {
        await sink.flush();
        await sink.close();
      }
      if (_logFile != null) {
        if (await _logFile!.exists()) {
          await _logFile!.writeAsString('');
        }
        final oldFile = File('${_logFile!.path}.old');
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
        _logSink = _logFile!.openWrite(mode: FileMode.write);
        _currentLogBytes = 0;
        _writeLine('=== LOGS CLEARED: ${DateTime.now()} ===');
      }
    } catch (e) {
      debugPrint('Clear logs failed: $e');
    }
  }
}

class ScopedLogger {
  final String _context;
  final String _consoleTag;
  final String _fileTag;

  ScopedLogger._(this._context)
    : _consoleTag = '${AppLogger.magenta}[$_context]${AppLogger.reset}',
      _fileTag = '[$_context]';

  ScopedLogger child(String sub) => ScopedLogger._('$_context.$sub');

  void d(String msg) {
    if (!kDebugMode) return;
    AppLogger._log(
      levelTag: '[DEBUG]',
      consoleContext: _consoleTag,
      fileContext: _fileTag,
      msg: msg,
      colorCode: AppLogger._gray,
      isVerboseOrDebug: true,
    );
  }

  void i(String msg) => AppLogger._log(
    levelTag: '[INFO]',
    consoleContext: _consoleTag,
    fileContext: _fileTag,
    msg: msg,
    colorCode: AppLogger._blue,
  );

  void w(String msg, [Object? e, StackTrace? s]) => AppLogger._log(
    levelTag: '[WARN]',
    consoleContext: _consoleTag,
    fileContext: _fileTag,
    msg: msg,
    colorCode: AppLogger._yellow,
    error: e,
    stackTrace: s,
  );

  void s(String msg) => AppLogger._log(
    levelTag: '[SUCCESS]',
    consoleContext: _consoleTag,
    fileContext: _fileTag,
    msg: '✓ $msg',
    colorCode: AppLogger._green,
  );

  void e(String msg, [Object? e, StackTrace? s]) => AppLogger._log(
    levelTag: '[ERROR]',
    consoleContext: _consoleTag,
    fileContext: _fileTag,
    msg: msg,
    colorCode: AppLogger._red,
    error: e,
    stackTrace: s,
  );

  void v(String msg) {
    if (!kDebugMode) return;
    AppLogger._log(
      levelTag: '[VERBOSE]',
      consoleContext: _consoleTag,
      fileContext: _fileTag,
      msg: msg,
      colorCode: AppLogger._gray,
      isVerboseOrDebug: true,
    );
  }

  void fail(String msg) => AppLogger._log(
    levelTag: '[ERROR]',
    consoleContext: _consoleTag,
    fileContext: _fileTag,
    msg: '✗ $msg',
    colorCode: AppLogger._red,
  );

  void warning(String msg) => AppLogger._log(
    levelTag: '[WARN]',
    consoleContext: _consoleTag,
    fileContext: _fileTag,
    msg: '⚠ $msg',
    colorCode: AppLogger._yellow,
  );

  void section(String title) {
    if (!kDebugMode) return;
    AppLogger.raw(
      '\n${AppLogger.magenta}${AppLogger.bold}=== $_context | $title ===${AppLogger.reset}',
      cleanMsg: '\n=== $_context | $title ===',
    );
  }
}
