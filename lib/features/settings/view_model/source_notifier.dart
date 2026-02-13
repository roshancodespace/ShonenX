import 'dart:async';

import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:get/instance_manager.dart';
import 'package:get/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/repositories/source_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/settings/model/source_model.dart';

part 'source_notifier.g.dart';

@Riverpod(keepAlive: true)
class SourceNotifier extends _$SourceNotifier {
  final SourceRepository _repo = SourceRepository();

  @override
  SourceState build() {
    ref.onDispose(() {
      _managerSubscription?.cancel();
      for (final sub in _extensionSubscriptions) {
        sub.cancel();
      }
    });
    return const SourceState(isLoading: true);
  }

  StreamSubscription? _managerSubscription;
  final List<StreamSubscription> _extensionSubscriptions = [];

  Future<void> initialize() async {
    try {
      final extensionManager = Get.find<ExtensionManager>();

      // Listen for manager changes (e.g., swapping between Aniyomi/Mangayomi)
      _managerSubscription?.cancel();
      _managerSubscription = extensionManager.currentManagerRx.listen(
        _onManagerChanged,
      );

      // Perform initial setup with the current manager
      await _onManagerChanged(extensionManager.currentManager);
    } catch (e, st) {
      AppLogger.e('Error initializing extensions: $e\n$st');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _onManagerChanged(Extension manager) async {
    // Clear old extension subscriptions
    for (final sub in _extensionSubscriptions) {
      sub.cancel();
    }
    _extensionSubscriptions.clear();

    // Subscribe to installed extension changes
    _extensionSubscriptions.addAll([
      manager.installedAnimeExtensions.listen(
        (extensions) => _updateExtensions(ItemType.anime, extensions),
      ),
      manager.installedMangaExtensions.listen(
        (extensions) => _updateExtensions(ItemType.manga, extensions),
      ),
      manager.installedNovelExtensions.listen(
        (extensions) => _updateExtensions(ItemType.novel, extensions),
      ),
    ]);

    // Fetch initial data
    fetchSources(ItemType.anime);

    for (final type in [ItemType.anime]) {
      List<Source> extensions = [];
      switch (type) {
        case ItemType.anime:
          extensions = await manager.getInstalledAnimeExtensions();
          break;
        case ItemType.manga:
          extensions = await manager.getInstalledMangaExtensions();
          break;
        case ItemType.novel:
          extensions = await manager.getInstalledNovelExtensions();
          break;
      }
      _updateExtensions(type, extensions);
    }

    state = state.copyWith(
      activeAnimeRepo: _repo.getActiveAnimeRepo(),
      activeMangaRepo: _repo.getActiveMangaRepo(),
      activeNovelRepo: _repo.getActiveNovelRepo(),
      isLoading: false,
    );

    _restoreActiveSources();
  }

  void _updateExtensions(ItemType type, List<Source> extensions) {
    switch (type) {
      case ItemType.anime:
        state = state.copyWith(installedAnimeExtensions: extensions);
        break;
      case ItemType.manga:
        state = state.copyWith(installedMangaExtensions: extensions);
        break;
      case ItemType.novel:
        state = state.copyWith(installedNovelExtensions: extensions);
        break;
    }
    _restoreActiveSources();
  }

  void _restoreActiveSources() {
    state = state.copyWith(
      activeAnimeSource: state.installedAnimeExtensions.firstWhereOrNull(
        (s) => s.id == _repo.getActiveAnimeSourceId(),
      ),
      activeMangaSource: state.installedMangaExtensions.firstWhereOrNull(
        (s) => s.id == _repo.getActiveMangaSourceId(),
      ),
      activeNovelSource: state.installedNovelExtensions.firstWhereOrNull(
        (s) => s.id == _repo.getActiveNovelSourceId(),
      ),
    );
  }

  void setActiveSource(Source source) {
    switch (source.itemType) {
      case ItemType.anime:
        state = state.copyWith(
          activeAnimeSource: source,
          lastUpdatedSourceType: 'ANIME',
        );
        _repo.saveActiveAnimeSourceId(source.id!);
        break;
      case ItemType.manga:
        state = state.copyWith(
          activeMangaSource: source,
          lastUpdatedSourceType: 'MANGA',
        );
        _repo.saveActiveMangaSourceId(source.id!);
        break;
      case ItemType.novel:
        state = state.copyWith(
          activeNovelSource: source,
          lastUpdatedSourceType: 'NOVEL',
        );
        _repo.saveActiveNovelSourceId(source.id!);
        break;
      case null:
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
    final manager = Get.find<ExtensionManager>().currentManager;
    if (mediaType == ItemType.anime) {
      if (state.activeAnimeRepo.isEmpty) return;
      await manager.fetchAvailableAnimeExtensions([state.activeAnimeRepo]);
    } else if (mediaType == ItemType.manga) {
      if (state.activeMangaRepo.isEmpty) return;
      await manager.fetchAvailableMangaExtensions([state.activeMangaRepo]);
    } else {
      if (state.activeNovelRepo.isEmpty) return;
      await manager.fetchAvailableNovelExtensions([state.activeNovelRepo]);
    }
  }

  Future<Pages> search(
    String query, {
    int page = 1,
    List filters = const [],
  }) async {
    try {
      if (state.activeAnimeSource == null) return Pages(list: []);
      return await state.activeAnimeSource!.methods.search(query, page, filters);
    } catch (err) {
      AppLogger.e(err);
      return Pages(list: []);
    }
  }

  Future<DMedia?> getDetails(DMedia media) async {
    try {
      if (state.activeAnimeSource == null) return null;
      return await state.activeAnimeSource!.methods.getDetail(media);
    } catch (err) {
      AppLogger.e(err);
      return null;
    }
  }

  Future<List<Video?>> getSources(DEpisode episode) async {
    try {
      if (state.activeAnimeSource == null) return [];
      return await state.activeAnimeSource!.methods.getVideoList(episode);
    } catch (err) {
      AppLogger.e(err);
      return [];
    }
  }

  Future<List<ServerData?>> getServers(
    String animeId,
    String episodeId,
    String episodeNumber,
  ) async {
    return [];
    //   try {
    //     if (state.activeAnimeSource == null) return [];
    //     final anilist = ref.read(anilistServiceProvider);
    //     final service = _getService(anilist);
    //     return state.activeAnimeSource!.isForShonenx ?? false
    //         ? await service.getSupportedServers(animeId, episodeId, episodeNumber)
    //         : [] as List<ServerData?>;
    //   } catch (err) {
    //     AppLogger.e(err);
    //     return [];
    //   }
    // }
  }
}
