import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/models/anilist/page_response.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';

enum WatchlistStatus {
  current,
  completed,
  paused,
  dropped,
  planning,
  favorites,
}

class WatchListState {
  final Map<WatchlistStatus, List<MediaListEntry>> lists;
  final Map<WatchlistStatus, PageInfo> pageInfo;
  final List<Media> favorites;
  final Set<WatchlistStatus> loadingStatuses;
  final Map<WatchlistStatus, String> errors;

  const WatchListState({
    this.lists = const {},
    this.pageInfo = const {},
    this.favorites = const [],
    this.loadingStatuses = const {},
    this.errors = const {},
  });

  List<MediaListEntry> get current => lists[WatchlistStatus.current] ?? [];
  List<MediaListEntry> get completed => lists[WatchlistStatus.completed] ?? [];
  List<MediaListEntry> get paused => lists[WatchlistStatus.paused] ?? [];
  List<MediaListEntry> get dropped => lists[WatchlistStatus.dropped] ?? [];
  List<MediaListEntry> get planning => lists[WatchlistStatus.planning] ?? [];

  bool isFavorite(int id) {
    return favorites.any((media) => media.id == id);
  }

  WatchListState copyWith({
    Map<WatchlistStatus, List<MediaListEntry>>? lists,
    Map<WatchlistStatus, PageInfo>? pageInfo,
    List<Media>? favorites,
    Set<WatchlistStatus>? loadingStatuses,
    Map<WatchlistStatus, String>? errors,
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
  AnimeRepository get _repo => ref.watch(animeRepositoryProvider);

  @override
  WatchListState build() => const WatchListState();

  Future<bool> ensureFavorite(int id) async {
    if (state.isFavorite(id)) {
      return true;
    }

    if (state.loadingStatuses.contains(WatchlistStatus.favorites)) {
      return state.favorites.any((media) => media.id == id);
    }

    await fetchListForStatus(WatchlistStatus.favorites, force: true);
    return state.favorites.any((media) => media.id == id);
  }

  Future<void> toggleFavorite(Media anime) async {
    final isFav = state.isFavorite(anime.id!);

    try {
      await _repo.toggleFavorite(anime.id!);

      List<Media> updatedFavorites;
      if (isFav) {
        updatedFavorites =
            state.favorites.where((m) => m.id != anime.id).toList();
      } else {
        updatedFavorites = [...state.favorites, anime];
      }

      state = state.copyWith(favorites: updatedFavorites);
    } catch (e) {
      state = state.copyWith(errors: {
        ...state.errors,
        WatchlistStatus.favorites: e.toString(),
      });
    }
  }

  Future<void> fetchListForStatus(
    WatchlistStatus status, {
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
      if (status == WatchlistStatus.favorites) {
        final favoritesData = await _repo.getFavorites();
        state = state.copyWith(
          favorites: favoritesData,
          loadingStatuses: {...state.loadingStatuses}..remove(status),
        );
      } else {
        final statusString = status.name.toUpperCase();
        final pageResponse = await _repo.getUserAnimeList(
          type: 'ANIME',
          status: statusString,
          page: page,
          perPage: perPage,
        );

        final oldList =
            page == 1 ? <MediaListEntry>[] : (state.lists[status] ?? []);
        final newList = [...oldList, ...pageResponse.mediaList];

        state = state.copyWith(
          lists: {
            ...state.lists,
            status: newList,
          },
          pageInfo: {
            ...state.pageInfo,
            status: PageInfo(
              total: pageResponse.pageInfo.total,
              currentPage: pageResponse.pageInfo.currentPage,
              lastPage: pageResponse.pageInfo.lastPage,
              hasNextPage: pageResponse.pageInfo.hasNextPage,
              perPage: pageResponse.pageInfo.perPage,
            ),
          },
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
    if (!auth.isLoggedIn) return showAppSnackBar('Locked', 'This operation required authenticaion');
    final status = WatchlistStatus.values.byName(entry.status.toLowerCase());

    final existingList = [...?state.lists[status]];

    final index = existingList.indexWhere((e) => e.id == entry.id);

    if (index >= 0) {
      existingList[index] = entry;
    } else {
      existingList.add(entry);
    }

    state = state.copyWith(
      lists: {
        ...state.lists,
        status: existingList,
      },
    );
  }

  Future<void> fetchAll({bool force = false}) async {
    await Future.wait(
      WatchlistStatus.values.map(
        (status) => fetchListForStatus(status, force: force),
      ),
    );
  }

  bool _hasDataForStatus(WatchlistStatus status) {
    if (status == WatchlistStatus.favorites) {
      return state.favorites.isNotEmpty;
    }
    return (state.lists[status] ?? []).isNotEmpty;
  }
}

final watchlistProvider =
    NotifierProvider<WatchlistNotifier, WatchListState>(WatchlistNotifier.new);
