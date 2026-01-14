import 'package:shonenx/core/registery/sources/anime/anime_provider.dart';
import 'package:shonenx/core/registery/sources/anime/animekai.dart';
import 'package:shonenx/core/registery/sources/anime/animepahe.dart';
import 'package:shonenx/core/registery/sources/anime/aniwatch/aniwatch.dart';
import 'package:shonenx/core/registery/sources/anime/aniwatch/hianime.dart';
import 'package:shonenx/core/registery/sources/anime/aniwatch/kaido.dart';
import 'package:shonenx/core/registery/sources/anime/anizone.dart';
import 'package:shonenx/core/registery/sources/anime/gojo.dart';
import 'package:shonenx/core/registery/sources/anime/animeonsen.dart';
import 'package:shonenx/core/utils/app_logger.dart';

enum RegistryStatus { uninitialized, initializing, initialized, error }

class AnimeSourceRegistry {
  final _providers = <String, AnimeProvider>{};
  RegistryStatus _status = RegistryStatus.uninitialized;
  String? _error;

  RegistryStatus get status => _status;
  String? get error => _error;
  bool get isInitialized => _status == RegistryStatus.initialized;

  bool register(String key, AnimeProvider provider) {
    if (key.isEmpty) return _fail('Empty key');
    _providers[key] = provider;
    AppLogger.i('Registered: $key');
    return true;
  }

  AnimeSourceRegistry() {
    _init();
  }

  AnimeSourceRegistry _init() {
    setStatus(RegistryStatus.initializing);
    try {
      register('aniwatch', AniwatchProvider());
      register('kaido', KaidoProvider());
      register('hianime', HiAnimeProvider());
      register('animekai', AnimekaiProvider());
      register('animepahe', AnimePaheProvider());
      register('gojo', GojoProvider());
      register('animeonsen', AnimeOnsenProvider());
      register('anizone', AnizoneProvider());
      setStatus(RegistryStatus.initialized);
      return this;
    } catch (e, stackTrace) {
      setStatus(RegistryStatus.error, 'Failed to initialize: $e\n$stackTrace');
      return this;
    }
  }

  AnimeProvider? get(String key) {
    if (!isInitialized) return _warn<AnimeProvider>('Not initialized: $key');
    return _providers[key] ?? _warn<AnimeProvider>('Not found: $key');
  }

  void setStatus(RegistryStatus status, [String? error]) {
    _status = status;
    _error = error;
    AppLogger.i('Status: $status');
    if (error != null) AppLogger.e('Error: $error');
  }

  void clear() {
    _providers.clear();
    AppLogger.i('Providers cleared');
  }

  bool has(String key) => _providers.containsKey(key);
  int get count => _providers.length;
  List<String> get keys => _providers.keys.toList();
  List<AnimeProvider> get values => _providers.values.toList();

  bool _fail(String msg) {
    AppLogger.w(msg);
    return false;
  }

  T? _warn<T>(String msg) {
    AppLogger.w(msg);
    return null;
  }
}
