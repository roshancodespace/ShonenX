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

  List<MediaListEntry> listFor(String status) => lists[status] ?? const [];

  bool isFavorite(int id) => favorites.any((m) => m.id == id);

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
  AnimeRepository get _repo => ref.read(animeRepositoryProvider);

  @override
  WatchListState build() => const WatchListState();

  void reset() {
    state = const WatchListState();
  }

  Future<bool> ensureFavorite(int id) async {
    if (state.isFavorite(id)) return true;
    if (state.loadingStatuses.contains('favorites')) {
      return state.isFavorite(id);
    }
    await fetchListForStatus('favorites', force: true);
    return state.isFavorite(id);
  }

  Future<void> toggleFavorite(Media anime) async {
    final id = anime.id;
    if (id == null) return;

    final wasFav = state.isFavorite(id);

    try {
      await _repo.toggleFavorite(id);

      final updated = wasFav
          ? state.favorites.where((m) => m.id != id).toList()
          : [...state.favorites, anime];

      state = state.copyWith(favorites: updated);
    } catch (e) {
      state = state.copyWith(
        errors: {...state.errors, 'favorites': e.toString()},
      );
    }
  }

  Future<void> fetchListForStatus(
    String status, {
    bool force = false,
    int page = 1,
    int perPage = 10,
  }) async {
    if (_shouldSkip(status, force, page)) return;

    state = state.copyWith(
      loadingStatuses: {...state.loadingStatuses, status},
      errors: {...state.errors}..remove(status),
    );

    try {
      if (status == 'favorites') {
        final data = await _repo.getFavorites();
        state = state.copyWith(favorites: data);
        return;
      }

      final res = await _repo.getUserAnimeList(
        type: 'ANIME',
        status: status,
        page: page,
        perPage: perPage,
      );

      final existing = page == 1 ? <MediaListEntry>[] : state.listFor(status);

      state = state.copyWith(
        lists: {
          ...state.lists,
          status: [...existing, ...res.mediaList],
        },
        pageInfo: {
          ...state.pageInfo,
          status: res.pageInfo,
        },
      );
    } catch (e) {
      state = state.copyWith(
        errors: {...state.errors, status: e.toString()},
      );
    } finally {
      final updated = {...state.loadingStatuses}..remove(status);
      state = state.copyWith(loadingStatuses: updated);
    }
  }

  void addEntry(MediaListEntry entry) {
    final auth = ref.read(authProvider);
    if (!auth.isAniListAuthenticated) {
      return showAppSnackBar(
        'Locked',
        'This operation requires authentication',
      );
    }

    final status = entry.status;
    final list = [...state.listFor(status)];

    final index = list.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      list[index] = entry;
    } else {
      list.add(entry);
    }

    state = state.copyWith(
      lists: {...state.lists, status: list},
    );
  }

  Future<void> fetchAll({bool force = false}) async {
    final statuses = await _repo.getSupportedStatuses();
    await Future.wait([
      ...statuses.map(
        (s) => fetchListForStatus(s, force: force),
      ),
      fetchListForStatus('favorites', force: force),
    ]);
  }

  bool _shouldSkip(String status, bool force, int page) {
    if (state.loadingStatuses.contains(status)) return true;
    if (force || page > 1) return false;

    return status == 'favorites'
        ? state.favorites.isNotEmpty
        : state.listFor(status).isNotEmpty;
  }
}

final watchlistProvider = NotifierProvider<WatchlistNotifier, WatchListState>(
  WatchlistNotifier.new,
);
