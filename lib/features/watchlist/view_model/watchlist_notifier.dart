import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/data/isar/track.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/core/repositories/local_media_repository.dart';
import 'package:shonenx/shared/auth/providers/auth_notifier.dart';
import 'package:shonenx/features/watchlist/view_model/watchlist_state.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';
import 'package:shonenx/data/isar/track.dart' as core;
import 'package:shonenx/data/isar/media.dart';

class WatchlistNotifier extends Notifier<WatchListState> {
  AnimeRepository get _repo => ref.read(animeRepositoryProvider);
  LocalMediaRepository get _localRepo => ref.read(localMediaRepoProvider);

  @override
  WatchListState build() {
    final auth = ref.read(authProvider);
    return WatchListState(isLocal: !auth.isAniListAuthenticated);
  }

  void toggleMode() {
    state = const WatchListState().copyWith(isLocal: !state.isLocal);
    fetchAll(force: true);
  }

  void setMode(bool isLocal) {
    if (state.isLocal == isLocal) return;
    state = const WatchListState().copyWith(isLocal: isLocal);
    fetchAll(force: true);
  }

  Future<bool> ensureFavorite(String id) async {
    // Check if loaded
    if (state.isFavorite(id)) return true;

    // Attempt fetch
    await fetchListForStatus('favorites', force: true);
    return state.isFavorite(id);
  }

  Future<void> toggleFavorite(UniversalMedia anime) async {
    final auth = ref.read(authProvider);

    // Decide based on mode, or fallback to local if not auth
    if (state.isLocal || !auth.isAniListAuthenticated) {
      await _toggleLocalFavorite(anime);
    } else {
      await _toggleRemoteFavorite(anime);
    }
  }

  Future<void> _toggleRemoteFavorite(UniversalMedia anime) async {
    final id = int.tryParse(anime.id);
    if (id == null) return;

    final wasFav = state.isFavorite(anime.id);

    try {
      await _repo.toggleFavorite(id);

      final updated = wasFav
          ? state.favorites.where((m) => m.id != anime.id).toList()
          : [...state.favorites, anime];

      state = state.copyWith(favorites: updated);
    } catch (e) {
      state = state.copyWith(
        errors: {...state.errors, 'favorites': e.toString()},
      );
    }
  }

  Future<void> _toggleLocalFavorite(UniversalMedia anime) async {
    await _localRepo.toggleFavorite(anime);
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
      if (state.isLocal) {
        return await _fetchLocal(status, page);
      } else {
        return await _fetchRemote(status, page, perPage);
      }
    } catch (e) {
      state = state.copyWith(errors: {...state.errors, status: e.toString()});
      return state;
    } finally {
      final updated = {...state.loadingStatuses}..remove(status);
      state = state.copyWith(loadingStatuses: updated);
    }
  }

  Future<WatchListState> _fetchRemote(
    String status,
    int page,
    int perPage,
  ) async {
    if (status == 'favorites') {
      final data = await _repo.getFavorites(page: page, perPage: perPage);
      final entries = data.data;

      final existing = page == 1 ? <UniversalMedia>[] : state.favorites;

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
  }

  Future<WatchListState> _fetchLocal(String status, int page) async {
    if (page > 1) return state;

    if (status == 'favorites') {
      final medias = await _localRepo.getFavoriteMedias();
      final entries = medias.map((m) => _mapMediaToUniversal(m)).toList();
      state = state.copyWith(favorites: entries);
    } else {
      TrackStatus? trackStatus = _mapStatus(status);
      if (trackStatus == null) {
        state = state.copyWith(lists: {...state.lists, status: []});
        return state;
      }

      final tracks = await _localRepo.getTracksByStatus(trackStatus);
      final entries = <UniversalMediaListEntry>[];

      final mediaIds = tracks
          .map((t) => int.tryParse(t.mediaId ?? '') ?? 0)
          .where((id) => id != 0)
          .toList();

      final medias = await _localRepo.getMedias(mediaIds);
      final mediaMap = {
        for (var m in medias)
          m?.id: ?m,
      };

      for (final track in tracks) {
        final int mediaId = int.tryParse(track.mediaId ?? '') ?? 0;
        final media = mediaMap[mediaId];
        if (media != null) {
          entries.add(_trackToEntry(track, media));
        }
      }

      state = state.copyWith(lists: {...state.lists, status: entries});
    }
    return state;
  }

  void addEntry(UniversalMediaListEntry entry) {
    if (!state.isLocal) {
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

  // Helpers

  TrackStatus? _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'watching':
      case 'current':
        return TrackStatus.watching;
      case 'completed':
        return TrackStatus.completed;
      case 'on_hold':
      case 'onhold':
        return TrackStatus.onHold;
      case 'dropped':
        return TrackStatus.dropped;
      case 'plan_to_watch':
      case 'planning':
        return TrackStatus.planToWatch;
      default:
        return null;
    }
  }

  UniversalMediaListEntry _trackToEntry(core.Track track, Media media) {
    return UniversalMediaListEntry(
      id: track.id.toString(),
      media: _mapMediaToUniversal(media),
      status: track.status.name.toUpperCase(),
      score: (track.score ?? 0).toDouble(),
      progress: track.progress ?? 0,
      repeat: 0,
      isPrivate: false,
      notes: '',
    );
  }

  UniversalMedia _mapMediaToUniversal(Media media) =>
      _localRepo.mapMediaToUniversal(media);
}

final watchlistProvider = NotifierProvider<WatchlistNotifier, WatchListState>(
  WatchlistNotifier.new,
);
