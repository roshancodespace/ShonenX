import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/api/sources/anime/aniwatch/aniwatch.dart';
import 'package:shonenx/api/sources/anime/aniwatch/hianime.dart';
import 'package:shonenx/api/registery/anime_source_registery.dart';
import 'package:shonenx/api/sources/anime/aniwatch/kaido.dart';

final animeSourceRegistryProvider = Provider<AnimeSourceRegistery>((ref) {
  final registry = AnimeSourceRegistery();
  // Register your providers. For example, the HiAnimeProvider:
  registry.registerProvider("hianime", HiAnimeProvider());
  registry.registerProvider("aniwatch", AniwatchProvider());
  registry.registerProvider("kaido", KaidoProvider());
  // If you have other providers, register them here.
  return registry;
});
