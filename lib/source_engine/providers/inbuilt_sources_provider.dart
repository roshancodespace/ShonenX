import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/providers/storage_provider.dart';
import 'package:shonenx/core/remote_config/providers/remote_config_provider.dart';
import 'package:shonenx/source_engine/inbuilt_sources/anime/anidb_source.dart';
import 'package:shonenx/source_engine/inbuilt_sources/anime/gojo_source.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';
import 'package:shonenx/source_engine/providers/manga_source.dart';

final inbuiltAnimeSourcesProvider = Provider<List<AnimeSource>>((ref) {
  final client = ref.watch(httpClientProvider);
  final storage = ref.watch(sharedPreferencesProvider);
  final remoteConfigService = ref.watch(remoteConfigServiceProvider);

  final allSources = [
    GojoSource(client: client, storage: storage),
    AnidbSource(client: client, storage: storage),
  ];

  return allSources.where((source) {
    return !remoteConfigService.isSourceDisabled(source.sourceInfo.id);
  }).toList();
}, name: 'inbuiltAnimeSourcesProvider');

final inbuiltMangaSourcesProvider = Provider<List<MangaSource>>((ref) {
  // final client = ref.watch(httpClientProvider);
  // final storage = ref.watch(sharedPreferencesProvider);
  final remoteConfigService = ref.watch(remoteConfigServiceProvider);

  final allSources = <MangaSource>[];

  return allSources.where((source) {
    return !remoteConfigService.isSourceDisabled(source.sourceInfo.id);
  }).toList();
}, name: 'inbuiltMangaSourcesProvider');
