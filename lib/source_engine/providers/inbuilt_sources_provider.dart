import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/source_engine/providers/anime_source.dart';
import 'package:shonenx/source_engine/providers/manga_source.dart';

final inbuiltAnimeSourcesProvider = Provider<List<AnimeSource>>((ref) {
  return [];
}, name: 'inbuiltAnimeSourcesProvider');

final inbuiltMangaSourcesProvider = Provider<List<MangaSource>>((ref) {
  return [];
}, name: 'inbuiltMangaSourcesProvider');
