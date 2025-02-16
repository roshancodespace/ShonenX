import 'package:shonenx/api/sources/anime/anime_provider.dart';

class AnimeSourceRegistery {
  final Map<String, AnimeProvider> _providers = {};

  // Register a provider by a key
  void registerProvider(String key, AnimeProvider provider) {
    _providers[key] = provider;
  }

  // Retrieve a provider by key
  AnimeProvider? getProvider(String key) => _providers[key];

  // List all registered providers
  List<AnimeProvider> get allProviders => _providers.values.toList();
}
