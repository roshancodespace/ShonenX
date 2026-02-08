import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/core/models/offline/manga.dart';
import 'package:shonenx/core/models/offline/track.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/features/watchlist/view_model/watchlist_state.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';
import 'package:shonenx/core/models/offline/track.dart' as core;

class WatchlistNotifier extends Notifier<WatchListState> {
  AnimeRepository get _repo => ref.read(animeRepositoryProvider);

  @override
  WatchListState build() {
    final trackStream = isar.tracks.watchLazy();
    final mangaStream = isar.mangas.watchLazy();

    final sub1 = trackStream.listen((_) {
      if (state.isLocal) _refreshActiveLists();
    });

    final sub2 = mangaStream.listen((_) {
      if (state.isLocal) _refreshActiveLists();
    });

    ref.onDispose(() {
      sub1.cancel();
      sub2.cancel();
    });

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

  Future<void> _refreshActiveLists() async {
    final loadedStatuses = state.lists.keys.toList();
    for (final status in loadedStatuses) {
      await fetchListForStatus(status, force: true);
    }
    if (state.favorites.isNotEmpty) {
      await fetchListForStatus('favorites', force: true);
    }
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
          ? state.favorites.where((m) => m.media.id != anime.id).toList()
          : [...state.favorites, _createDummyEntry(anime)];

      state = state.copyWith(favorites: updated);
    } catch (e) {
      state = state.copyWith(
        errors: {...state.errors, 'favorites': e.toString()},
      );
    }
  }

  Future<void> _toggleLocalFavorite(UniversalMedia anime) async {
    final int id = int.tryParse(anime.id) ?? 0;
    if (id == 0) return;

    Manga? manga = await isar.mangas.get(id);
    if (manga == null) {
      // Must ensure it exists
      final newManga = Manga(
        id: id,
        source: 'LOCAL',
        author: anime.staff.isNotEmpty
            ? anime.staff.first.name?.full
            : 'Unknown',
        artist: '',
        genre: anime.genres,
        imageUrl: anime.coverImage.large ?? anime.coverImage.medium ?? '',
        lang: '',
        link: anime.siteUrl ?? '',
        name:
            anime.title.english ??
            anime.title.romaji ??
            anime.title.native ??
            'Unknown',
        status: _mapMediaStatus(anime.status), // Reuse helper
        description: anime.description ?? '',
        itemType: ItemType.anime,
        dateAdded: DateTime.now().millisecondsSinceEpoch,
      );
      await isar.writeTxn(() async {
        await isar.mangas.put(newManga);
      });
      manga = newManga;
    }

    final newFavStatus = !(manga.favorite ?? false);

    await isar.writeTxn(() async {
      manga!.favorite = newFavStatus;
      await isar.mangas.put(manga);
    });
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
      final entries = data.data.map((m) => _createDummyEntry(m)).toList();

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
  }

  Future<WatchListState> _fetchLocal(String status, int page) async {
    if (page > 1) return state;

    if (status == 'favorites') {
      final mangas = await isar.mangas.filter().favoriteEqualTo(true).findAll();

      final entries = mangas.map((m) => _mangaToEntry(m, 'CURRENT')).toList();

      state = state.copyWith(favorites: entries);
    } else {
      TrackStatus? trackStatus = _mapStatus(status);
      if (trackStatus == null) {
        state = state.copyWith(lists: {...state.lists, status: []});
        return state;
      }

      final tracks = await isar.tracks
          .filter()
          .statusEqualTo(trackStatus)
          .findAll();

      final entries = <UniversalMediaListEntry>[];

      for (final track in tracks) {
        final manga = await isar.mangas.get(track.mangaId ?? -1);
        if (manga != null) {
          entries.add(_trackToEntry(track, manga));
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

  UniversalMediaListEntry _createDummyEntry(UniversalMedia anime) {
    return UniversalMediaListEntry(
      id: 'fav_${anime.id}',
      media: anime,
      status: 'CURRENT',
      score: 0,
      progress: 0,
      repeat: 0,
      isPrivate: false,
      notes: '',
    );
  }

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

  Status _mapMediaStatus(String? status) {
    if (status == null) return Status.unknown;
    switch (status.toUpperCase()) {
      case 'FINISHED':
        return Status.completed;
      case 'RELEASING':
        return Status.ongoing;
      case 'CANCELLED':
        return Status.canceled;
      default:
        return Status.unknown;
    }
  }

  UniversalMediaListEntry _mangaToEntry(Manga manga, String status) {
    return UniversalMediaListEntry(
      id: manga.id.toString(),
      media: _mapMangaToUniversal(manga),
      status: status,
      score: 0,
      progress: manga.lastRead ?? 0,
      repeat: 0,
      isPrivate: false,
      notes: '',
    );
  }

  UniversalMediaListEntry _trackToEntry(core.Track track, Manga manga) {
    return UniversalMediaListEntry(
      id: track.id.toString(),
      media: _mapMangaToUniversal(manga),
      status: track.status.name.toUpperCase(),
      score: (track.score ?? 0).toDouble(),
      progress: track.lastChapterRead ?? 0,
      repeat: 0,
      isPrivate: false,
      notes: '',
    );
  }

  UniversalMedia _mapMangaToUniversal(Manga manga) {
    return UniversalMedia(
      id: manga.id.toString(),
      title: UniversalTitle(
        romaji: manga.name,
        english: manga.name,
        native: manga.name,
      ),
      coverImage: UniversalCoverImage(
        large: manga.imageUrl,
        medium: manga.imageUrl,
      ),
      description: manga.description,
      status: manga.status.name.toUpperCase(),
      source: manga.source,
    );
  }
}

final watchlistProvider = NotifierProvider<WatchlistNotifier, WatchListState>(
  WatchlistNotifier.new,
);
