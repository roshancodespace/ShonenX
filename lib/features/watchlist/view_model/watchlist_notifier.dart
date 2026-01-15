import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/core/models/universal/universal_page_response.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';

class WatchListState {
  final Map<String, List<UniversalMediaListEntry>> lists;
  final Map<String, UniversalPageInfo> pageInfo;
  final List<UniversalMediaListEntry> favorites;
  final Set<String> loadingStatuses;
  final Map<String, String> errors;
  // Generic list for unified access if needed, mostly for 'favorites' which is special-cased in old code
  // but let's keep it separate for now as per existing logic.

  const WatchListState({
    this.lists = const {},
    this.pageInfo = const {},
    this.favorites = const [],
    this.loadingStatuses = const {},
    this.errors = const {},
  });

  List<UniversalMediaListEntry> listFor(String status) =>
      lists[status] ?? const [];

  bool isFavorite(String id) => favorites.any((m) => m.media.id == id);

  WatchListState copyWith({
    Map<String, List<UniversalMediaListEntry>>? lists,
    Map<String, UniversalPageInfo>? pageInfo,
    List<UniversalMediaListEntry>? favorites,
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

  Future<bool> ensureFavorite(String id) async {
    if (state.isFavorite(id)) return true;
    if (state.loadingStatuses.contains('favorites')) {
      return state.isFavorite(id);
    }
    await fetchListForStatus('favorites', force: true);
    return state.isFavorite(id);
  }

  Future<void> toggleFavorite(UniversalMedia anime) async {
    final id = int.tryParse(anime.id);
    if (id == null) return; // TODO: handle string IDs for non-anilist

    final wasFav = state.isFavorite(anime.id);

    try {
      await _repo.toggleFavorite(id);

      final updated = wasFav
          ? state.favorites.where((m) => m.media.id != anime.id).toList()
          : [
              ...state.favorites,
              UniversalMediaListEntry(
                id: 'fav_${anime.id}', // dummy ID
                media: anime,
                status: 'CURRENT',
                score: 0,
                progress: 0,
                repeat: 0,
                isPrivate: false,
                notes: '',
              ),
            ];

      state = state.copyWith(favorites: updated);
    } catch (e) {
      state = state.copyWith(
        errors: {...state.errors, 'favorites': e.toString()},
      );
    }
  }

  Future<WatchListState> fetchListForStatus(
    String status, {
    bool force = false,
    int page = 1,
    int perPage = 25,
  }) async {
    if (_shouldSkip(status, force, page)) return state;

    state = state.copyWith(
      loadingStatuses: {...state.loadingStatuses, status},
      errors: {...state.errors}..remove(status),
    );

    try {
      if (status == 'favorites') {
        final data = await _repo.getFavorites(page: page, perPage: perPage);
        final entries = data.data
            .map(
              (m) => UniversalMediaListEntry(
                id: 'fav_${m.id}',
                media: m,
                status: 'CURRENT',
                score: 0,
                progress: 0,
                repeat: 0,
                isPrivate: false,
                notes: '',
              ),
            )
            .toList();

        final existing = page == 1
            ? <UniversalMediaListEntry>[]
            : state.favorites;

        state = state.copyWith(
          favorites: [...existing, ...entries],
          pageInfo: {...state.pageInfo, 'favorites': data.pageInfo},
        );
        return state;
      }

      final res = await _repo.getUserAnimeList(
        type: 'ANIME',
        status: status,
        page: page,
        perPage: perPage,
      );

      final existing = page == 1
          ? <UniversalMediaListEntry>[]
          : state.listFor(status);

      state = state.copyWith(
        lists: {
          ...state.lists,
          status: [...existing, ...res.data],
        },
        pageInfo: {...state.pageInfo, status: res.pageInfo},
      );
      return state;
    } catch (e) {
      state = state.copyWith(errors: {...state.errors, status: e.toString()});
      return state;
    } finally {
      final updated = {...state.loadingStatuses}..remove(status);
      state = state.copyWith(loadingStatuses: updated);
    }
  }

  void addEntry(UniversalMediaListEntry entry) {
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

    state = state.copyWith(lists: {...state.lists, status: list});
  }

  Future<void> fetchAll({bool force = false}) async {
    final statuses = await _repo.getSupportedStatuses();
    await Future.wait([
      ...statuses.map((s) => fetchListForStatus(s, force: force)),
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
