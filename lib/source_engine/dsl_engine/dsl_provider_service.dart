import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/source_engine/dsl_engine/dsl_runtime.dart';

final dslRuntimeProvider = Provider<DSLRuntime>((ref) {
  return DSLRuntime(httpClient: ref.watch(httpClientProvider));
});

final dslProvidersProvider =
    AsyncNotifierProvider<
      DSLProvidersNotifier,
      Map<String, Map<String, dynamic>>
    >(DSLProvidersNotifier.new);

class DSLProvidersNotifier
    extends AsyncNotifier<Map<String, Map<String, dynamic>>> {
  final _log = AppLogger.scope('DSLProvidersNotifier');

  @override
  Future<Map<String, Map<String, dynamic>>> build() async {
    _log.i('Loading DSL providers...');
    final providers = await _loadAllFromDisk();
    _log.i('Loaded ${providers.length} DSL providers');
    return providers;
  }

  Future<Directory> _getDslDir() async {
    final dir = await getApplicationDocumentsDirectory();

    final path = Platform.isAndroid || Platform.isIOS || Platform.isMacOS
        ? p.join(dir.path, 'dsl_providers')
        : p.join(dir.path, 'ShonenX', 'dsl_providers');

    final dslDir = Directory(path);

    if (!await dslDir.exists()) {
      await dslDir.create(recursive: true);
    }

    return dslDir;
  }

  Future<Map<String, Map<String, dynamic>>> _loadAllFromDisk() async {
    try {
      final dir = await _getDslDir();

      final loaded = <String, Map<String, dynamic>>{};

      final files = await dir.list().toList();

      for (final file in files) {
        if (file is! File || !file.path.endsWith('.json')) {
          continue;
        }

        try {
          final content = await file.readAsString();
          final decoded = jsonDecode(content);

          if (decoded is Map && decoded['id'] != null) {
            loaded[decoded['id'].toString()] = Map<String, dynamic>.from(
              decoded,
            );
          }
        } catch (e, st) {
          _log.e('Failed to parse DSL file: ${file.path}', '$e\n$st');
        }
      }

      return loaded;
    } catch (e, st) {
      _log.e('Critical error loading DSL providers', '$e\n$st');

      return {};
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return _loadAllFromDisk();
    });
  }

  Future<void> saveProvider(String id, Map<String, dynamic> json) async {
    try {
      final dir = await _getDslDir();

      final file = File(p.join(dir.path, '$id.json'));

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
      );

      await reload();
    } catch (e, st) {
      _log.e('Failed to save provider: $id', '$e\n$st');

      rethrow;
    }
  }

  Future<void> deleteProvider(String id) async {
    try {
      final dir = await _getDslDir();

      final file = File(p.join(dir.path, '$id.json'));

      if (await file.exists()) {
        await file.delete();
      }

      await reload();
    } catch (e, st) {
      _log.e('Failed to delete provider: $id', '$e\n$st');

      rethrow;
    }
  }
}
