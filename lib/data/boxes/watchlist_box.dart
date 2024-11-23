import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';

class WatchlistBox {
  static const String boxName = 'watchlist';
  late Box<WatchlistModel> _box;
  WatchlistModel? _watchlistModel;

  // Get listenable for the box
  ValueListenable<Box<WatchlistModel>> listenable() => _box.listenable();

  // Get specific field listenable
  ValueListenable<Box<WatchlistModel>> listenToRecentlyWatched() {
    return _box.listenable(keys: [0]);
  }

  ValueListenable<Box<WatchlistModel>> listenToContinueWatching() {
    return _box.listenable(keys: [0]);
  }

  ValueListenable<Box<WatchlistModel>> listenToFavorites() {
    return _box.listenable(keys: [0]);
  }

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

  // Recently Watched Methods
  Future<void> addToRecentlyWatched(RecentlyWatchedItem item) async {
    var recentlyWatched = _watchlistModel?.recentlyWatched ?? [];
    recentlyWatched.removeWhere((element) => element.id == item.id);
    recentlyWatched.insert(0, item);
    if (recentlyWatched.length > 20) {
      recentlyWatched = recentlyWatched.sublist(0, 20);
    }
    _watchlistModel?.recentlyWatched = recentlyWatched;
    await _box.put(0, _watchlistModel!);
  }

  Future<void> removeFromRecentlyWatched(String id) async {
    _watchlistModel?.recentlyWatched?.removeWhere((item) => item.id == id);
    await _box.put(0, _watchlistModel!);
  }

  List<RecentlyWatchedItem> getRecentlyWatched() {
    return _watchlistModel?.recentlyWatched ?? [];
  }

  Future<void> clearRecentlyWatched() async {
    _watchlistModel?.recentlyWatched?.clear();
    await _box.put(0, _watchlistModel!);
  }

  bool isRecentlyWatched(String id) {
    return _watchlistModel?.recentlyWatched?.any((item) => item.id == id) ?? false;
  }

  // Continue Watching Methods
  Future<void> addToContinueWatching(ContinueWatchingItem item) async {
    debugPrint("addToContinueWatching() : ${item.duration}");
    var continueWatching = _watchlistModel?.continueWatching ?? [];
    int existingIndex = continueWatching.indexWhere((element) => element.id == item.id);
    if (existingIndex != -1) {
      continueWatching[existingIndex] = item;
    } else {
      continueWatching.insert(0, item);
    }
    _watchlistModel?.continueWatching = continueWatching;
    await _box.put(0, _watchlistModel!);
  }

  Future<void> removeFromContinueWatching(String id) async {
    _watchlistModel?.continueWatching?.removeWhere((item) => item.id == id);
    await _box.put(0, _watchlistModel!);
  }

  Future<void> updateContinueWatchingTimestamp(String id, String timestamp) async {
    var item = getContinueWatchingById(id);
    if (item != null) {
      var updatedItem = ContinueWatchingItem(
        id: item.id,
        name: item.name,
        poster: item.poster,
        episode: item.episode,
        episodeId: item.episodeId,
        timestamp: timestamp,
        type: item.type,
        title: item.title
      );
      await addToContinueWatching(updatedItem);
    }
  }

  Future<void> updateContinueWatchingEpisode(String id, int episode, String episodeId) async {
    var item = getContinueWatchingById(id);
    if (item != null) {
      var updatedItem = ContinueWatchingItem(
        id: item.id,
        title: item.title,
        name: item.name,
        poster: item.poster,
        episode: episode,
        episodeId: episodeId,
        timestamp: "0:00",  // Reset timestamp for new episode
        type: item.type,
      );
      await addToContinueWatching(updatedItem);
    }
  }

  List<ContinueWatchingItem> getContinueWatching() {
    return _watchlistModel?.continueWatching ?? [];
  }

  ContinueWatchingItem? getContinueWatchingById(String id) {
    debugPrint("getContinueWatchingById() : ${_watchlistModel?.continueWatching}");
    try {
      return _watchlistModel?.continueWatching?.firstWhere(
        (item) => item.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> clearContinueWatching() async {
    _watchlistModel?.continueWatching?.clear();
    await _box.put(0, _watchlistModel!);
  }

  bool isContinueWatching(String id) {
    return _watchlistModel?.continueWatching?.any((item) => item.id == id) ?? false;
  }

  // Favorites Methods
  Future<void> addToFavorites(AnimeItem item) async {
    if (!isFavorite(item.id)) {
      _watchlistModel?.favorites?.add(item);
      await _box.put(0, _watchlistModel!);
    }
  }

  Future<void> removeFromFavorites(String id) async {
    _watchlistModel?.favorites?.removeWhere((item) => item.id == id);
    await _box.put(0, _watchlistModel!);
  }

  Future<void> toggleFavorite(AnimeItem item) async {
    if (isFavorite(item.id)) {
      await removeFromFavorites(item.id);
    } else {
      await addToFavorites(item);
    }
  }

  List<AnimeItem> getFavorites() {
    return _watchlistModel?.favorites ?? [];
  }

  AnimeItem? getFavoriteById(String id) {
    try {
      return _watchlistModel?.favorites?.firstWhere(
        (item) => item.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  bool isFavorite(String id) {
    return _watchlistModel?.favorites?.any((item) => item.id == id) ?? false;
  }

  Future<void> clearFavorites() async {
    _watchlistModel?.favorites?.clear();
    await _box.put(0, _watchlistModel!);
  }

  // Search Methods
  // List<BaseAnimeCard> searchAllLists(String query) {
  //   query = query.toLowerCase();
  //   List<BaseAnimeCard> results = [];
    
  //   // Search in recently watched
  //   results.addAll(
  //     _watchlistModel?.recentlyWatched?.where(
  //       (item) => item.name.toLowerCase().contains(query)
  //     ) ?? []
  //   );
    
  //   // Search in continue watching
  //   results.addAll(
  //     _watchlistModel?.continueWatching?.where(
  //       (item) => item.name.toLowerCase().contains(query)
  //     ) ?? []
  //   );
    
  //   // Search in favorites
  //   results.addAll(
  //     _watchlistModel?.favorites?.where(
  //       (item) => item.name.toLowerCase().contains(query)
  //     ) ?? []
  //   );
    
  //   return results;
  // }

  // Statistics Methods
  int get totalWatchedAnime => _watchlistModel?.recentlyWatched?.length ?? 0;
  int get totalContinueWatching => _watchlistModel?.continueWatching?.length ?? 0;
  int get totalFavorites => _watchlistModel?.favorites?.length ?? 0;

  // Map<String, int> getAnimeTypeDistribution() {
  //   Map<String, int> distribution = {};
    
  //   void countType(String type) {
  //     distribution[type] = (distribution[type] ?? 0) + 1;
  //   }

  //   _watchlistModel?.recentlyWatched?.forEach((item) => countType(item.type));
  //   _watchlistModel?.continueWatching?.forEach((item) => countType(item.type));
  //   _watchlistModel?.favorites?.forEach((item) => countType(item.type));

  //   return distribution;
  // }

  // General Methods
  Future<void> clearAll() async {
    _watchlistModel = WatchlistModel(
      recentlyWatched: [],
      continueWatching: [],
      favorites: [],
    );
    await _box.put(0, _watchlistModel!);
  }

  Future<void> dispose() async {
    await _box.close();
  }

  // Backup & Restore Methods
  Map<String, dynamic> exportData() {
    return {
      'recentlyWatched': _watchlistModel?.recentlyWatched?.map((e) => {
        'name': e.name,
        'poster': e.poster,
        'type': e.type,
        'id': e.id,
      }).toList(),
      'continueWatching': _watchlistModel?.continueWatching?.map((e) => {
        'name': e.name,
        'title': e.title,
        'poster': e.poster,
        'type': e.type,
        'id': e.id,
        'episode': e.episode,
        'episodeId': e.episodeId,
        'timestamp': e.timestamp,
      }).toList(),
      'favorites': _watchlistModel?.favorites?.map((e) => {
        'name': e.name,
        'poster': e.poster,
        'type': e.type,
        'id': e.id,
      }).toList(),
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    _watchlistModel = WatchlistModel(
      recentlyWatched: (data['recentlyWatched'] as List?)?.map((e) => RecentlyWatchedItem(
        name: e['name'],
        poster: e['poster'],
        type: e['type'],
        id: e['id'],
      )).toList(),
      continueWatching: (data['continueWatching'] as List?)?.map((e) => ContinueWatchingItem(
        name: e['name'],
        title: e['title'],
        poster: e['poster'],
        type: e['type'],
        id: e['id'],
        episode: e['episode'],
        episodeId: e['episodeId'],
        timestamp: e['timestamp'],
      )).toList(),
      favorites: (data['favorites'] as List?)?.map((e) => AnimeItem(
        name: e['name'],
        poster: e['poster'],
        type: e['type'],
        id: e['id'],
      )).toList(),
    );
    await _box.put(0, _watchlistModel!);
  }
}