import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/repositories/source_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core_new/eval/lib.dart';
import 'package:shonenx/core_new/eval/model/m_manga.dart';
import 'package:shonenx/core_new/eval/model/m_pages.dart';
import 'package:shonenx/core_new/extensions/extensions_provider.dart';
import 'package:shonenx/core_new/extensions/fetch_anime_sources.dart';
import 'package:shonenx/core_new/extensions/fetch_manga_sources.dart';
import 'package:shonenx/core_new/extensions/fetch_novel_sources.dart';
import 'package:shonenx/core_new/models/manga.dart';
import 'package:shonenx/core_new/models/source.dart';
import 'package:shonenx/core_new/models/video.dart';
import 'package:shonenx/features/settings/model/source_model.dart';
import 'package:collection/collection.dart';

final sourceProvider = NotifierProvider<SourceNotifier, SourceState>(
  SourceNotifier.new,
);

class SourceNotifier extends Notifier<SourceState> {
  final SourceRepository _repo = SourceRepository();

  @override
  SourceState build() {
    return const SourceState(isLoading: true);
  }

  Future<void> initialize() async {
    try {
      fetchSources(ItemType.anime);
      fetchSources(ItemType.manga);
      fetchSources(ItemType.novel);
      final animeExtensions =
          await ref.read(getExtensionsStreamProvider(ItemType.anime).future);
      final mangaExtensions =
          await ref.read(getExtensionsStreamProvider(ItemType.manga).future);
      final novelExtensions =
          await ref.read(getExtensionsStreamProvider(ItemType.novel).future);

      state = state.copyWith(
        installedAnimeExtensions:
            animeExtensions.where((ext) => ext.isAdded ?? false).toList(),
        installedMangaExtensions:
            mangaExtensions.where((ext) => ext.isAdded ?? false).toList(),
        installedNovelExtensions:
            novelExtensions.where((ext) => ext.isAdded ?? false).toList(),
        activeAnimeRepo: _repo.getActiveAnimeRepo(),
        activeMangaRepo: _repo.getActiveMangaRepo(),
        activeNovelRepo: _repo.getActiveNovelRepo(),
        activeAnimeSource: animeExtensions
            .where((ext) => ext.isAdded ?? false)
            .firstWhereOrNull(
                (source) => source.id == _repo.getActiveAnimeSourceId()),
        activeMangaSource: mangaExtensions
            .where((ext) => ext.isAdded ?? false)
            .firstWhereOrNull(
                (source) => source.id == _repo.getActiveMangaSourceId()),
        activeNovelSource: novelExtensions
            .where((ext) => ext.isAdded ?? false)
            .firstWhereOrNull(
                (source) => source.id == _repo.getActiveNovelSourceId()),
      );
    } catch (e, st) {
      AppLogger.e('Error initializing extensions: $e\n$st');
      state = state.copyWith(isLoading: false);
    }
  }

  void setActiveSource(Source source) {
    switch (source.itemType) {
      case ItemType.anime:
        state = state.copyWith(
            activeAnimeSource: source, lastUpdatedSourceType: 'ANIME');
        _repo.saveActiveAnimeSourceId(source.id!);
        break;
      case ItemType.manga:
        state = state.copyWith(
            activeMangaSource: source, lastUpdatedSourceType: 'MANGA');
        _repo.saveActiveMangaSourceId(source.id!);
        break;
      case ItemType.novel:
        state = state.copyWith(
            activeNovelSource: source, lastUpdatedSourceType: 'NOVEL');
        _repo.saveActiveNovelSourceId(source.id!);
        break;
    }
  }

  void setActiveRepo(String repoUrl, ItemType mediaType) {
    switch (mediaType) {
      case ItemType.anime:
        state = state.copyWith(activeAnimeRepo: repoUrl);
        _repo.saveActiveAnimeRepo(repoUrl);
        break;
      case ItemType.manga:
        state = state.copyWith(activeMangaRepo: repoUrl);
        _repo.saveActiveMangaRepo(repoUrl);
        break;
      case ItemType.novel:
        state = state.copyWith(activeNovelRepo: repoUrl);
        _repo.saveActiveNovelRepo(repoUrl);
        break;
    }
  }

  Future<void> fetchSources(ItemType mediaType) async {
    if (mediaType == ItemType.anime) {
      if (state.activeAnimeRepo.isEmpty) return;
      await ref
          .read(fetchAnimeSourcesListProvider(id: null, reFresh: true).future);
    } else if (mediaType == ItemType.manga) {
      if (state.activeMangaRepo.isEmpty) return;
      await ref
          .read(fetchMangaSourcesListProvider(id: null, reFresh: true).future);
    } else {
      if (state.activeNovelRepo.isEmpty) return;
      await ref
          .read(fetchNovelSourcesListProvider(id: null, reFresh: true).future);
    }
  }

  Future<MPages> search(String query,
      {int page = 1, List filters = const []}) async {
    try {
      AppLogger.d('Searching');
      final service = getExtensionService(state.activeAnimeSource!);
      return service.search(query, page, filters);
    } catch (err) {
      AppLogger.e(err);
      return MPages(list: []);
    }
  }

  Future<MManga?> getDetails(String url) async {
    try {
      AppLogger.d('Searching');
      final service = getExtensionService(state.activeAnimeSource!);
      return service.getDetail(url);
    } catch (err) {
      AppLogger.e(err);
      return null;
    }
  }

  Future<List<Video?>> getSources(String url) async {
    try {
      AppLogger.d('Searching');
      final service = getExtensionService(state.activeAnimeSource!);
      return service.getVideoList(url);
    } catch (err) {
      AppLogger.e(err);
      return [];
    }
  }
}
