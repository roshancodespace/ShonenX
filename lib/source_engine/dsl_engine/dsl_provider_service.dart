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
    return await _loadAllFromDisk();
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
      if (!dir.existsSync()) return {};

      final files = dir.listSync();
      final loaded = <String, Map<String, dynamic>>{};

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content);
            if (json is Map && json['id'] != null) {
              loaded[json['id'].toString()] = Map<String, dynamic>.from(json);
            }
          } catch (e) {
            _log.e('Failed to parse DSL file: ${file.path}', e);
          }
        }
      }
      return loaded;
    } catch (e) {
      _log.e('Critical error loading DSL directory', e);
      return {};
    }
  }

  Future<void> saveProvider(String id, Map<String, dynamic> json) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dir = await _getDslDir();
      final file = File(p.join(dir.path, '$id.json'));
      await file.writeAsString(jsonEncode(json));
      final currentState = Map<String, Map<String, dynamic>>.from(
        state.value ?? {},
      );
      currentState[id] = json;
      return currentState;
    });
  }

  Future<void> deleteProvider(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dir = await _getDslDir();
      final file = File(p.join(dir.path, '$id.json'));
      if (await file.exists()) await file.delete();
      final currentState = Map<String, Map<String, dynamic>>.from(
        state.value ?? {},
      );
      currentState.remove(id);
      return currentState;
    });
  }
}