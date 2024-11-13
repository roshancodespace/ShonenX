import 'package:hive/hive.dart';

part 'watchlist_model.g.dart';

abstract class BaseAnimeCard {
  String get name;
  String get poster;
  String get id;
  String get type;
}

@HiveType(typeId: 1)
class WatchlistModel extends HiveObject {
  @HiveField(0)
  List<RecentlyWatchedItem>? recentlyWatched;

  @HiveField(1)
  List<ContinueWatchingItem>? continueWatching;

  @HiveField(2)
  List<AnimeItem>? favorites;

  WatchlistModel({
    this.recentlyWatched,
    this.continueWatching,
    this.favorites,
  });
}

@HiveType(typeId: 2)
class RecentlyWatchedItem extends HiveObject implements BaseAnimeCard {
  @override
  @HiveField(0)
  final String name;

  @override
  @HiveField(1)
  final String poster;

  @override
  @HiveField(2)
  final String type; // e.g., "TV", "OTV"

  @override
  @HiveField(3)
  final String id;

  RecentlyWatchedItem({
    required this.name,
    required this.poster,
    required this.type,
    required this.id,
  });
}

@HiveType(typeId: 3)
class ContinueWatchingItem extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String poster;

  @HiveField(2)
  final int episode;

  @HiveField(3)
  final String episodeId;

  @HiveField(4)
  final String timestamp;

  ContinueWatchingItem({
    required this.name,
    required this.poster,
    required this.episode,
    required this.episodeId,
    required this.timestamp,
  });
}

@HiveType(typeId: 4)
class AnimeItem extends HiveObject implements BaseAnimeCard{
  @override
  @HiveField(0)
  final String name;

  @override
  @HiveField(1)
  final String poster;

  @override
  @HiveField(2)
  final String id;

  @override
  @HiveField(3)
  final String type;

  AnimeItem({
    required this.name,
    required this.poster,
    required this.id,
    required this.type
  });
}
