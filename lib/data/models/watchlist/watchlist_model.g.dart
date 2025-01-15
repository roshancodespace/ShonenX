// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watchlist_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WatchlistModelAdapter extends TypeAdapter<WatchlistModel> {
  @override
  final int typeId = 1;

  @override
  WatchlistModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WatchlistModel(
      recentlyWatched: (fields[0] as List?)?.cast<RecentlyWatchedItem>(),
      continueWatching: (fields[1] as List?)?.cast<ContinueWatchingItem>(),
      favorites: (fields[2] as List?)?.cast<AnimeItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, WatchlistModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.recentlyWatched)
      ..writeByte(1)
      ..write(obj.continueWatching)
      ..writeByte(2)
      ..write(obj.favorites);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchlistModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecentlyWatchedItemAdapter extends TypeAdapter<RecentlyWatchedItem> {
  @override
  final int typeId = 2;

  @override
  RecentlyWatchedItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecentlyWatchedItem(
      name: fields[0] as String,
      poster: fields[1] as String,
      type: fields[2] as String?,
      id: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RecentlyWatchedItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.poster)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentlyWatchedItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContinueWatchingItemAdapter extends TypeAdapter<ContinueWatchingItem> {
  @override
  final int typeId = 3;

  @override
  ContinueWatchingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContinueWatchingItem(
      id: fields[5] as String,
      name: fields[0] as String,
      poster: fields[1] as String,
      episode: fields[2] as int,
      episodeId: fields[3] as String,
      title: fields[7] as String,
      isCompleted: fields[8] as bool?,
      timestamp: fields[4] as String,
      duration: fields[9] as String,
      type: fields[6] as String?,
      watchedEpisodes: (fields[10] as List?)?.cast<String?>(),
    );
  }

  @override
  void write(BinaryWriter writer, ContinueWatchingItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.poster)
      ..writeByte(2)
      ..write(obj.episode)
      ..writeByte(3)
      ..write(obj.episodeId)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.id)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.title)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(9)
      ..write(obj.duration)
      ..writeByte(10)
      ..write(obj.watchedEpisodes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContinueWatchingItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AnimeItemAdapter extends TypeAdapter<AnimeItem> {
  @override
  final int typeId = 4;

  @override
  AnimeItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnimeItem(
      name: fields[0] as String,
      poster: fields[1] as String,
      id: fields[2] as String,
      type: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AnimeItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.poster)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimeItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
