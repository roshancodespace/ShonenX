import 'dart:io';

class Env {
  static late final Map<String, String> _vars;

  static Future<void> init([String path = '.env']) async {
    final file = File(path);
    final map = <String, String>{};

    if (await file.exists()) {
      final lines = await file.readAsLines();

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
    }

    _vars = map;
  }

  static String? get(String key) => Platform.environment[key] ?? _vars[key];
}
