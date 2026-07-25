import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:shonenx/core/network/http_client.dart';

final runtimeUpdateProvider = FutureProvider.autoDispose<String?>((ref) async {
  if (!bridge.AnymeXRuntimeBridge.controller.isReady.value) return null;

  final installedVersion = bridge.AnymeXRuntimeBridge.installedVersion;

  try {
    final http = HTTP();
    final response = await http.get(
      'https://api.github.com/repos/RyanYuuki/AnymeXExtensionRuntimeBridge/releases/latest',
    );

    final latestVersion = (response.json['tag_name'] as String?)
        ?.replaceAll('v', '')
        .trim();

    final currentVersion = installedVersion.replaceAll('v', '').trim();

    if (latestVersion != null && latestVersion != currentVersion) {
      return latestVersion;
    }
  } catch (_) {}

  return null;
});
