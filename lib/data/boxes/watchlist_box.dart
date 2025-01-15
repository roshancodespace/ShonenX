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
    _box = Hive.box<WatchlistModel>(boxName);
    _watchlistModel = _box.get(0) ??
        WatchlistModel(
          recentlyWatched: [],
          continueWatching: [],
          favorites: [],
        );
    await _box.put(0, _watchlistModel!);
  }

  // Continue Watching Methods
  Future<void> updateContinueWatching(ContinueWatchingItem item) async {
    var list = _watchlistModel?.continueWatching ?? [];
    int index = list.indexWhere((element) => element.id == item.id);
    if (index != -1) {
      // Update existing item
      list[index] = item; // Replace with the updated item
    } else {
      // Add as a new item
      list.insert(0, item);
    }

    _watchlistModel?.continueWatching = list;
    await _box.put(0, _watchlistModel!);
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
    // Retrieve the existing item by ID
    var cItem = getContinueWatchingById(id);
    if (cItem != null) {
      // Copy the current list of watched episodes
      List<String> watchedEpisodes = List.from(cItem.watchedEpisodes ?? []);

      // Add the episode to the watched list if it is marked as watched
      if (markAsWatched && !watchedEpisodes.contains(episodeId)) {
        watchedEpisodes.add(episodeId);
      }

      var updatedItem = ContinueWatchingItem(
        id: item!.id,
        title: item.title,
        name: item.name,
        poster: item.poster,
        episode: episode, // Update to the current episode
        episodeId: episodeId, // Current episode ID
        timestamp: timestamp, // Current timestamp
        duration: duration, // Current duration
        type: cItem.type, // Retain original type
        watchedEpisodes: watchedEpisodes, // Preserved watched episodes
        isCompleted: markAsWatched
            ? cItem.isCompleted
            : false, // Maintain completion logic
      );

      // Update the continue watching list
      await updateContinueWatching(updatedItem);
    } else {
      if (item != null) {
        updateContinueWatching(item);
      }
    }
  }

  ContinueWatchingItem? getContinueWatchingById(String id) {
    try {
      return _watchlistModel?.continueWatching?.firstWhere(
        (item) => item.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  List<ContinueWatchingItem> getContinueWatching() {
    return _watchlistModel?.continueWatching
            ?.where((item) => !item.isCompleted!)
            .toList() ??
        [];
  }

  // Favorites Methods
  Future<void> toggleFavorite(AnimeItem item) async {
    var favorites = _watchlistModel?.favorites ?? [];
    int index = favorites.indexWhere((element) => element.id == item.id);

    if (index != -1) {
      favorites.removeAt(index);
    } else {
      favorites.add(item);
    }

    _watchlistModel?.favorites = favorites;
    await _box.put(0, _watchlistModel!);
  }

  Future<void> removeFavorites(List<String> ids) async {
    if (_watchlistModel?.favorites == null || ids.isEmpty) return;

    _watchlistModel?.favorites?.removeWhere((item) => ids.contains(item.id));
    await _box.put(0, _watchlistModel!);
  }

  bool isFavorite(String id) {
    return _watchlistModel?.favorites?.any((item) => item.id == id) ?? false;
  }

  List<AnimeItem> getFavorites() {
    return _watchlistModel?.favorites ?? [];
  }

  // Recently Watched Methods
  Future<void> addToRecentlyWatched(RecentlyWatchedItem item) async {
    var list = _watchlistModel?.recentlyWatched ?? [];
    list.removeWhere((element) => element.id == item.id);
    list.insert(0, item);

    // Keep only last 20 items
    if (list.length > 20) {
      list = list.sublist(0, 20);
    }

    _watchlistModel?.recentlyWatched = list;
    await _box.put(0, _watchlistModel!);
  }

  Future<void> removeRecentlyWatched(List<String> ids) async {
    if (_watchlistModel?.recentlyWatched == null || ids.isEmpty) return;

    _watchlistModel?.recentlyWatched
        ?.removeWhere((item) => ids.contains(item.id));
    await _box.put(0, _watchlistModel!);
  }

  List<RecentlyWatchedItem> getRecentlyWatched() {
    return _watchlistModel?.recentlyWatched ?? [];
  }

  // Cleanup
  Future<void> dispose() async {
    await _box.close();
  }
}
