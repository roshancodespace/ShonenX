import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/source_engine/dsl_engine/dsl_context.dart';

typedef DSLHelperFunction =
    Future<dynamic> Function(List<dynamic> args, ExecutionContext context);

class HelperRegistry {
  final HTTP client;
  final Map<String, DSLHelperFunction> _helpers = {};
  final _log = AppLogger.scope(HelperRegistry);

  HelperRegistry({required this.client}) {
    _registerDefaultHelpers();
  }

  void register(String name, DSLHelperFunction func) {
    _helpers[name] = func;
  }

  Future<dynamic> execute(
    String name,
    List<dynamic> args,
    ExecutionContext context,
  ) async {
    final helper = _helpers[name];
    if (helper == null) {
      throw Exception("Helper function '$name' is not registered.");
    }
    return await helper(args, context);
  }

  void _registerDefaultHelpers() {
    // --- Network ---
    register('fetch', (args, context) async {
      final url = args[0].toString();
      final headers = args.length > 1 && args[1] is Map
          ? Map<String, String>.from(args[1] as Map)
          : null;
      final res = await client.get(url, headers: headers);
      context.lastResponse = res;
      try {
        return res.json;
      } catch (_) {
        return res.body;
      }
    });

    register('get', (args, context) async {
      final url = args[0].toString();
      final headers = args.length > 1 && args[1] is Map
          ? Map<String, String>.from(args[1] as Map)
          : null;
      final res = await client.get(url, headers: headers);
      context.lastResponse = res;
      return {
        'body': res.body,
        'statusCode': res.statusCode,
        'headers': res.headers ?? {},
      };
    });

    register('post', (args, context) async {
      final url = args[0].toString();
      final body = args.length > 1 ? args[1] : null;
      final headers = args.length > 2 && args[2] is Map
          ? Map<String, String>.from(args[2] as Map)
          : null;
      final res = await client.post(url, body: body, headers: headers);
      context.lastResponse = res;
      return {
        'body': res.body,
        'statusCode': res.statusCode,
        'headers': res.headers ?? {},
      };
    });

    // --- HTML ---
    register('select', (args, context) async {
      final input = args[0];
      final selector = args[1].toString();
      dom.Element? root;

      if (input is dom.Element) {
        root = input;
      } else if (input is dom.Document) {
        root = input.documentElement;
      } else if (input is String) {
        root = html_parser.parse(input).documentElement;
      }

      if (root == null) return null;
      final matched = root.querySelector(selector);
      if (matched != null) {
        context.lastHtmlElement = matched;
      }
      return matched;
    });

    register('selectAll', (args, context) async {
      final input = args[0];
      final selector = args[1].toString();
      dom.Element? root;

      if (input is dom.Element) {
        root = input;
      } else if (input is dom.Document) {
        root = input.documentElement;
      } else if (input is String) {
        root = html_parser.parse(input).documentElement;
      }

      if (root == null) return <dom.Element>[];
      return root.querySelectorAll(selector);
    });

    register('text', (args, context) async {
      final input = args[0];
      if (input is dom.Element) {
        return input.text.trim();
      }
      if (input is List<dom.Element> && input.isNotEmpty) {
        return input.first.text.trim();
      }
      return input?.toString().trim();
    });

    register('html', (args, context) async {
      final input = args[0];
      if (input is dom.Element) {
        return input.outerHtml;
      }
      return input?.toString();
    });

    register('attr', (args, context) async {
      final input = args[0];
      final name = args[1].toString();
      if (input is dom.Element) {
        return input.attributes[name];
      }
      if (input is List<dom.Element> && input.isNotEmpty) {
        return input.first.attributes[name];
      }
      return null;
    });

    register('exists', (args, context) async {
      final input = args[0];
      final selector = args[1].toString();
      dom.Element? root;

      if (input is dom.Element) {
        root = input;
      } else if (input is dom.Document) {
        root = input.documentElement;
      } else if (input is String) {
        root = html_parser.parse(input).documentElement;
      }

      return root?.querySelector(selector) != null;
    });

    // --- JSON ---
    register('jsonPath', (args, context) async {
      final jsonObj = args[0];
      final path = args[1].toString();
      return _getJsonPath(jsonObj, path);
    });

    register('value', (args, context) async {
      return args[0];
    });

    // --- Strings ---
    register('trim', (args, context) async {
      return args[0]?.toString().trim();
    });

    register('replace', (args, context) async {
      final str = args[0]?.toString() ?? '';
      final pattern = args[1].toString();
      final replacement = args[2].toString();
      return str.replaceAll(pattern, replacement);
    });

    register('split', (args, context) async {
      final str = args[0]?.toString() ?? '';
      final pattern = args[1].toString();
      return str.split(pattern);
    });

    register('regex', (args, context) async {
      final str = args[0]?.toString() ?? '';
      final pattern = args[1].toString();
      final groupIdx = args.length > 2
          ? int.tryParse(args[2].toString()) ?? 1
          : 1;
      final match = RegExp(pattern).firstMatch(str);
      if (match == null) return null;
      return match.groupCount >= groupIdx
          ? match.group(groupIdx)
          : match.group(0);
    });

    register('lowercase', (args, context) async {
      return args[0]?.toString().toLowerCase();
    });

    register('uppercase', (args, context) async {
      return args[0]?.toString().toUpperCase();
    });

    // --- URLs ---
    register('absoluteUrl', (args, context) async {
      final baseUrl = args[0].toString();
      final relativeUrl = args[1].toString();
      try {
        return Uri.parse(baseUrl).resolve(relativeUrl).toString();
      } catch (_) {
        return relativeUrl;
      }
    });

    register('joinUrl', (args, context) async {
      final p1 = args[0].toString();
      final p2 = args[1].toString();
      if (p1.endsWith('/') && p2.startsWith('/')) {
        return p1 + p2.substring(1);
      } else if (!p1.endsWith('/') && !p2.startsWith('/')) {
        return '$p1/$p2';
      } else {
        return p1 + p2;
      }
    });

    // --- Collections ---
    register('first', (args, context) async {
      final list = args[0];
      if (list is List && list.isNotEmpty) return list.first;
      return null;
    });

    register('last', (args, context) async {
      final list = args[0];
      if (list is List && list.isNotEmpty) return list.last;
      return null;
    });

    register('filter', (args, context) async {
      final list = args[0];
      if (list is! List) return [];
      if (args.length == 3) {
        final key = args[1];
        final val = args[2];
        return list.where((item) => item is Map && item[key] == val).toList();
      }
      return list;
    });

    register('flatten', (args, context) async {
      final list = args[0];
      if (list is! List) return [];
      return list.expand((x) => x is List ? x : [x]).toList();
    });

    // --- Numbers ---
    register('parseInt', (args, context) async {
      return int.tryParse(args[0]?.toString() ?? '');
    });

    register('parseDouble', (args, context) async {
      return double.tryParse(args[0]?.toString() ?? '');
    });

    // --- Encoding ---
    register('base64Decode', (args, context) async {
      try {
        return utf8.decode(base64.decode(args[0].toString()));
      } catch (_) {
        return null;
      }
    });

    register('base64Encode', (args, context) async {
      try {
        return base64.encode(utf8.encode(args[0].toString()));
      } catch (_) {
        return null;
      }
    });

    // --- Utilities ---
    register('cache', (args, context) async {
      final key = args[0].toString();
      if (args.length > 1) {
        final val = args[1];
        context.cache[key] = val;
        return val;
      }
      return context.cache[key];
    });

    register('variable', (args, context) async {
      final name = args[0].toString();
      if (args.length > 1) {
        final val = args[1];
        context.setVariable(name, val);
        return val;
      }
      return context.getVariable(name);
    });

    register('log', (args, context) async {
      final val = args[0];
      _log.i('DSL Log: $val');
      return val;
    });
  }

  dynamic _getJsonPath(dynamic obj, String path) {
    if (obj == null) return null;
    final parts = path.split('.');
    dynamic current = obj;
    for (final part in parts) {
      if (current == null) return null;
      if (part.contains('[') && part.endsWith(']')) {
        final bracketIndex = part.indexOf('[');
        final key = part.substring(0, bracketIndex);
        final indexStr = part.substring(bracketIndex + 1, part.length - 1);
        final index = int.tryParse(indexStr);
        if (key.isNotEmpty) {
          if (current is Map) {
            current = current[key];
          } else {
            return null;
          }
        }
        if (index != null && current is List) {
          if (index >= 0 && index < current.length) {
            current = current[index];
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        if (current is Map) {
          current = current[part];
        } else {
          return null;
        }
      }
    }
    return current;
  }
}
