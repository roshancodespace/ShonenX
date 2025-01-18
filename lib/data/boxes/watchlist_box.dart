import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';

class WatchlistBox {
  static const String boxName = 'watchlist';
  late Box<WatchlistModel> _box;
  WatchlistModel? _watchlistModel;

  // Single listenable for the box
  ValueListenable<Box<WatchlistModel>> listenable() => _box.listenable();

  // Initialize the box
  Future<void> init() async {
    try {
      _box = Hive.box<WatchlistModel>(boxName);
      _watchlistModel = _box.get(0) ?? WatchlistModel(
        recentlyWatched: [],
        continueWatching: [],
        favorites: [],
      );
      await _box.put(0, _watchlistModel!);
    } catch (e) {
      // Handle initialization error (e.g., log the error)
    }
  }

  // Continue Watching Methods
  Future<void> updateContinueWatching(ContinueWatchingItem item) async {
    try {
      final list = _watchlistModel?.continueWatching ?? [];
      final index = list.indexWhere((element) => element.id == item.id);

      if (index != -1) {
        // Update existing item
        list[index] = item; // Replace with the updated item
      } else {
        // Add as a new item
        list.insert(0, item);
      }

      _watchlistModel?.continueWatching = list;
      await _box.put(0, _watchlistModel!);
    } catch (e) {
      // Handle update error (e.g., log the error)
    }
  }

  Future<void> updateEpisodeProgress(
    String id, {
    required int episode,
    required String episodeId,
    required String timestamp,
    required String duration,
    ContinueWatchingItem? item,
    bool markAsWatched = false,
  }) async {
    try {
      final cItem = getContinueWatchingById(id);
      if (cItem != null) {
        final watchedEpisodes = List<String>.from(cItem.watchedEpisodes ?? []);

        // Add the episode to the watched list if it is marked as watched
        if (markAsWatched && !watchedEpisodes.contains(episodeId)) {
          watchedEpisodes.add(episodeId);
        }

        final updatedItem = ContinueWatchingItem(
          id: item!.id,
          title: item.title,
          name: item.name,
          poster: item.poster,
          episode: episode,
          episodeId: episodeId,
          timestamp: timestamp,
          duration: duration,
          type: cItem.type,
          watchedEpisodes: watchedEpisodes,
          isCompleted: markAsWatched ? cItem.isCompleted : false,
        );

        await updateContinueWatching(updatedItem);
      } else if (item != null) {
        await updateContinueWatching(item);
      }
    } catch (e) {
      // Handle episode progress update error (e.g., log the error)
    }
  }

  ContinueWatchingItem? getContinueWatchingById(String id) {
    if (_watchlistModel?.continueWatching == null) {
      // Handle uninitialized watchlist (e.g., log the error)
      return null;
    }

    for (var item in _watchlistModel!.continueWatching!) {
      if (item.id == id) {
        return item;
      }
    }
    
    return null;
  }

  List<ContinueWatchingItem> getContinueWatching() {
    return _watchlistModel?.continueWatching
            ?.where((item) => !(item.isCompleted ?? false))
            .toList() ??
        [];
  }

  // Favorites Methods
  Future<void> toggleFavorite(AnimeItem item) async {
    try {
      final favorites = _watchlistModel?.favorites ?? [];
      final index = favorites.indexWhere((element) => element.id == item.id);

      if (index != -1) {
        favorites.removeAt(index);
      } else {
        favorites.add(item);
      }

      _watchlistModel?.favorites = favorites;
      await _box.put(0, _watchlistModel!);
    } catch (e) {
      // Handle toggle favorite error (e.g., log the error)
    }
  }

  Future<void> removeFavorites(List<String> ids) async {
    try {
      if (_watchlistModel?.favorites == null || ids.isEmpty) return;

      _watchlistModel?.favorites?.removeWhere((item) => ids.contains(item.id));
      await _box.put(0, _watchlistModel!);
    } catch (e) {
      // Handle remove favorites error (e.g., log the error)
    }
  }

  bool isFavorite(String id) {
    return _watchlistModel?.favorites?.any((item) => item.id == id) ?? false;
  }

  List<AnimeItem> getFavorites() {
    return _watchlistModel?.favorites ?? [];
  }

  // Recently Watched Methods
  Future<void> addToRecentlyWatched(RecentlyWatchedItem item) async {
    try {
      final list = _watchlistModel?.recentlyWatched ?? [];
      list.removeWhere((element) => element.id == item.id);
      list.insert(0, item);

      // Keep only last 20 items
      if (list.length > 20) {
        list.removeRange(20, list.length);
      }

      _watchlistModel?.recentlyWatched = list;
      await _box.put(0, _watchlistModel!);
    } catch (e) {
      // Handle add to recently watched error (e.g., log the error)
    }
  }

  Future<void> removeRecentlyWatched(List<String> ids) async {
    try {
      if (_watchlistModel?.recentlyWatched == null || ids.isEmpty) return;

      _watchlistModel?.recentlyWatched?.removeWhere((item) => ids.contains(item.id));
      await _box.put(0, _watchlistModel!);
    } catch (e) {
      // Handle remove recently watched error (e.g., log the error)
    }
  }

  List<RecentlyWatchedItem> getRecentlyWatched() {
    return _watchlistModel?.recentlyWatched ?? [];
  }

  // Cleanup
  Future<void> dispose() async {
    await _box.close();
  }
}
