import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
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
  final List<MediaListEntry> current;
  final List<MediaListEntry> completed;
  final List<MediaListEntry> paused;
  final List<MediaListEntry> dropped;
  final List<MediaListEntry> planning;
  final List<Media> favorites;
  final Set<WatchlistStatus> loadingStatuses;
  final Map<WatchlistStatus, String> errors;

  const WatchListState({
    this.current = const [],
    this.completed = const [],
    this.paused = const [],
    this.dropped = const [],
    this.planning = const [],
    this.favorites = const [],
    this.loadingStatuses = const {},
    this.errors = const {},
  });

 

  WatchListState copyWith({
    List<MediaListEntry>? current,
    List<MediaListEntry>? completed,
    List<MediaListEntry>? paused,
    List<MediaListEntry>? dropped,
    List<MediaListEntry>? planning,
    List<Media>? favorites,
    Set<WatchlistStatus>? loadingStatuses,
    Map<WatchlistStatus, String>? errors,
  }) {
    return WatchListState(
      current: current ?? this.current,
      completed: completed ?? this.completed,
      paused: paused ?? this.paused,
      dropped: dropped ?? this.dropped,
      planning: planning ?? this.planning,
      favorites: favorites ?? this.favorites,
      loadingStatuses: loadingStatuses ?? this.loadingStatuses,
      errors: errors ?? this.errors,
    );
  }
}

class WatchlistNotifier extends Notifier<WatchListState> {
  AnimeRepository get _repo => ref.watch(animeRepositoryProvider);

  @override
  WatchListState build() {
    return const WatchListState();
  }

  Future<void> fetchListForStatus(WatchlistStatus status,
      {bool force = false}) async {
    final hasData = _hasDataForStatus(status);
    if (hasData && !force) return;

    if (state.loadingStatuses.contains(status)) return;

    state = state.copyWith(
      loadingStatuses: {...state.loadingStatuses, status},
      errors: Map.from(state.errors)
        ..remove(status), // Clear previous errors for this tab
    );

    try {
      if (status == WatchlistStatus.favorites) {
        final favoritesData = await _repo.getFavorites();
        state = state.copyWith(
          favorites: favoritesData,
          loadingStatuses: {...state.loadingStatuses}..remove(status),
        );
      }  else {
        // For all other statuses, call getUserAnimeList.
        final statusString = status.name.toUpperCase();
        final collection = await _repo.getUserAnimeList(type: 'ANIME', status: statusString);
        final entries = collection.lists.isNotEmpty ? collection.lists[0].entries : <MediaListEntry>[];

        state = _copyWithStatus(status, entries).copyWith(
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

  // Helper to check if a list for a status already has data.
  bool _hasDataForStatus(WatchlistStatus status) {
    switch (status) {
      case WatchlistStatus.current:
        return state.current.isNotEmpty;
      case WatchlistStatus.completed:
        return state.completed.isNotEmpty;
      case WatchlistStatus.paused:
        return state.paused.isNotEmpty;
      case WatchlistStatus.dropped:
        return state.dropped.isNotEmpty;
      case WatchlistStatus.planning:
        return state.planning.isNotEmpty;
      case WatchlistStatus.favorites:
        return state.favorites.isNotEmpty;
    }
  }

  // Helper to update the correct list based on status.
  WatchListState _copyWithStatus(
      WatchlistStatus status, List<MediaListEntry> entries) {
    switch (status) {
      case WatchlistStatus.current:
        return state.copyWith(current: entries);
      case WatchlistStatus.completed:
        return state.copyWith(completed: entries);
      case WatchlistStatus.paused:
        return state.copyWith(paused: entries);
      case WatchlistStatus.dropped:
        return state.copyWith(dropped: entries);
      case WatchlistStatus.planning:
        return state.copyWith(planning: entries);
      case WatchlistStatus.favorites:
        return state; // Should not happen
    }
  }

  // Future<void> fetchWatchList() async {
  //   // Add a guard to prevent multiple fetches at the same time.
  //   if (state.isLoading) return;

  //   state = state.copyWith(isLoading: true, error: null);
  //   try {
  //     final results = await Future.wait([
  //       _repo.getUserAnimeList(type: 'ANIME', status: 'CURRENT'),
  //       _repo.getUserAnimeList(type: 'ANIME', status: 'COMPLETED'),
  //       _repo.getUserAnimeList(type: 'ANIME', status: 'PAUSED'),
  //       _repo.getUserAnimeList(type: 'ANIME', status: 'DROPPED'),
  //       _repo.getUserAnimeList(type: 'ANIME', status: 'PLANNING'),
  //       _repo.getFavorites(),
  //     ]);

  //     // Safely cast and access the results.
  //     final watching = results[0] as MediaListCollection;
  //     final completed = results[1] as MediaListCollection;
  //     final paused = results[2] as MediaListCollection;
  //     final dropped = results[3] as MediaListCollection;
  //     final planning = results[4] as MediaListCollection;
  //     final favorites = results[5] as List<Media>;

  //     // Helper function for safe parsing to avoid crashes.
  //     List<MediaList> _getEntries(MediaListCollection collection) {
  //       return collection.lists.isNotEmpty ? collection.lists[0].entries : [];
  //     }

  //     state = state.copyWith(
  //       watching: _getEntries(watching),
  //       completed: _getEntries(completed),
  //       paused: _getEntries(paused),
  //       dropped: _getEntries(dropped),
  //       planning: _getEntries(planning),
  //       favorites: favorites,
  //       isLoading: false,
  //     );
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, error: e.toString());
  //   }
  // }
}

final watchlistProvider = NotifierProvider<WatchlistNotifier, WatchListState>(
  WatchlistNotifier.new,
);
