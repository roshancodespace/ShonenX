import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/core/remote_config/models/remote_config.dart';
import 'package:shonenx/core/remote_config/services/remote_config_service.dart';

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RemoteConfigService(prefs);
});

// Provides the current RemoteConfig (or null if not loaded yet)
final remoteConfigProvider = Provider<RemoteConfig?>((ref) {
  return ref.watch(remoteConfigServiceProvider).config;
});

class RemoteConfigNotifier extends AsyncNotifier<RemoteConfig?> {
  @override
  Future<RemoteConfig?> build() async {
    final service = ref.read(remoteConfigServiceProvider);
    await service.init();
    return service.config;
  }
}

final remoteConfigStateProvider =
    AsyncNotifierProvider<RemoteConfigNotifier, RemoteConfig?>(
      RemoteConfigNotifier.new,
    );
