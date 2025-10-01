import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/models/anilist/page_response.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';

class WatchListState {
  final Map<String, List<MediaListEntry>> lists;
  final Map<String, PageInfo> pageInfo;
  final List<Media> favorites;
  final Set<String> loadingStatuses;
  final Map<String, String> errors;

  const WatchListState({
    this.lists = const {},
    this.pageInfo = const {},
    this.favorites = const [],
    this.loadingStatuses = const {},
    this.errors = const {},
  });

  List<MediaListEntry> listFor(String status) => lists[status] ?? [];

  bool isFavorite(int id) => favorites.any((media) => media.id == id);

  WatchListState copyWith({
    Map<String, List<MediaListEntry>>? lists,
    Map<String, PageInfo>? pageInfo,
    List<Media>? favorites,
    Set<String>? loadingStatuses,
    Map<String, String>? errors,
  }) {
    return WatchListState(
      lists: lists ?? this.lists,
      pageInfo: pageInfo ?? this.pageInfo,
      favorites: favorites ?? this.favorites,
      loadingStatuses: loadingStatuses ?? this.loadingStatuses,
      errors: errors ?? this.errors,
    );
  }
}

class WatchlistNotifier extends Notifier<WatchListState> {
  AnimeRepository get repo => ref.watch(animeRepositoryProvider);

  @override
  WatchListState build() => const WatchListState();

  Future<bool> ensureFavorite(int id) async {
    if (state.isFavorite(id)) return true;

    if (state.loadingStatuses.contains('favorites')) {
      return state.favorites.any((media) => media.id == id);
    }

    await fetchListForStatus('favorites', force: true);
    return state.favorites.any((media) => media.id == id);
  }

  Future<void> toggleFavorite(Media anime) async {
    final isFav = state.isFavorite(anime.id!);

    try {
      await repo.toggleFavorite(anime.id!);

      final updatedFavorites = isFav
          ? state.favorites.where((m) => m.id != anime.id).toList()
          : [...state.favorites, anime];

      state = state.copyWith(favorites: updatedFavorites);
    } catch (e) {
      state =
          state.copyWith(errors: {...state.errors, 'favorites': e.toString()});
    }
  }

  Future<void> fetchListForStatus(
    String status, {
    bool force = false,
    int page = 1,
    int perPage = 10,
  }) async {
    final alreadyHasData = _hasDataForStatus(status);
    if (alreadyHasData && !force && page == 1) return;
    if (state.loadingStatuses.contains(status)) return;

    // Mark as loading
    state = state.copyWith(
      loadingStatuses: {...state.loadingStatuses, status},
      errors: {...state.errors}..remove(status),
    );

    try {
      if (status == 'favorites') {
        final favoritesData = await repo.getFavorites();
        state = state.copyWith(
          favorites: favoritesData,
          loadingStatuses: {...state.loadingStatuses}..remove(status),
        );
      } else {
        final pageResponse = await repo.getUserAnimeList(
          type: 'ANIME',
          status: status,
          page: page,
          perPage: perPage,
        );

        final oldList =
            page == 1 ? <MediaListEntry>[] : (state.lists[status] ?? []);
        final newList = [...oldList, ...pageResponse.mediaList];

        state = state.copyWith(
          lists: {...state.lists, status: newList},
          pageInfo: {...state.pageInfo, status: pageResponse.pageInfo},
          loadingStatuses: {...state.loadingStatuses}..remove(status),
        );
      }
    } catch (e) {
      state = state.copyWith(
        errors: {...state.errors, status: e.toString()},
        loadingStatuses: {...state.loadingStatuses}..remove(status),
      );
    }
  }

  void addEntry(MediaListEntry entry) {
    final auth = ref.read(authProvider);
    if (!auth.isAniListAuthenticated) {
      return showAppSnackBar(
          'Locked', 'This operation requires authentication');
    }

    final status = entry.status;
    final existingList = [...?state.lists[status]];

    final index = existingList.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      existingList[index] = entry;
    } else {
      existingList.add(entry);
    }

    state = state.copyWith(
      lists: {...state.lists, status: existingList},
    );
  }

  Future<void> fetchAll({bool force = false}) async {
    final statuses = await repo.getSupportedStatuses();
    await Future.wait(
      [...statuses, 'favorites'].map(
        (status) => fetchListForStatus(status, force: force),
      ),
    );
  }

  bool _hasDataForStatus(String status) {
    if (status == 'favorites') {
      return state.favorites.isNotEmpty;
    }
    return (state.lists[status] ?? []).isNotEmpty;
  }
}

final watchlistProvider =
    NotifierProvider<WatchlistNotifier, WatchListState>(WatchlistNotifier.new);
