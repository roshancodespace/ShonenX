import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/api/sources/anime/animekai.dart';
import 'package:shonenx/api/sources/anime/animepahe.dart';
import 'package:shonenx/api/sources/anime/aniwatch/aniwatch.dart';
import 'package:shonenx/api/sources/anime/aniwatch/hianime.dart';
import 'package:shonenx/api/registery/anime_source_registery.dart';
import 'package:shonenx/api/sources/anime/aniwatch/kaido.dart';

class AnimeSourceRegistryNotifier extends StateNotifier<AnimeSourceRegistery> {
  AnimeSourceRegistryNotifier() : super(AnimeSourceRegistery()) {
    _initializeRegistry(null);
  }

  void _initializeRegistry(String? apiUrl) {
    state = AnimeSourceRegistery();
    state.registerProvider("hianime", HiAnimeProvider(customApiUrl: apiUrl));
    state.registerProvider("aniwatch", AniwatchProvider(customApiUrl: apiUrl));
    state.registerProvider("kaido", KaidoProvider(customApiUrl: apiUrl));
    state.registerProvider("animekai", AnimekaiProvider(customApiUrl: apiUrl));
    state.registerProvider("animepahe", AnimePaheProvider(customApiUrl: apiUrl));
  }

  void updateApiUrl(String newApiUrl) {
    _initializeRegistry(newApiUrl);
  }

  void resetApiUrl() {
    _initializeRegistry(null);
  }
}

final animeSourceRegistryProvider =
    StateNotifierProvider<AnimeSourceRegistryNotifier, AnimeSourceRegistery>(
        (ref) => AnimeSourceRegistryNotifier());
