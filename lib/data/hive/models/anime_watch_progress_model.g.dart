// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_watch_progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnimeWatchProgressEntryAdapter
    extends TypeAdapter<AnimeWatchProgressEntry> {
  @override
  final int typeId = 7;

  @override
  AnimeWatchProgressEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnimeWatchProgressEntry(
      animeId: fields[0] as int,
      animeTitle: fields[1] as String,
      animeFormat: fields[2] as String,
      animeCover: fields[3] as String,
      totalEpisodes: fields[4] as int,
      episodesProgress: (fields[5] as Map).cast<int, EpisodeProgress>(),
      lastUpdated: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AnimeWatchProgressEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.animeId)
      ..writeByte(1)
      ..write(obj.animeTitle)
      ..writeByte(2)
      ..write(obj.animeFormat)
      ..writeByte(3)
      ..write(obj.animeCover)
      ..writeByte(4)
      ..write(obj.totalEpisodes)
      ..writeByte(5)
      ..write(obj.episodesProgress)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimeWatchProgressEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EpisodeProgressAdapter extends TypeAdapter<EpisodeProgress> {
  @override
  final int typeId = 8;

  @override
  EpisodeProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EpisodeProgress(
      episodeNumber: fields[0] as int,
      episodeTitle: fields[1] as String,
      episodeThumbnail: fields[2] as String?,
      progressInSeconds: fields[3] as int?,
      durationInSeconds: fields[4] as int?,
      isCompleted: fields[5] as bool,
      watchedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, EpisodeProgress obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.episodeNumber)
      ..writeByte(1)
      ..write(obj.episodeTitle)
      ..writeByte(2)
      ..write(obj.episodeThumbnail)
      ..writeByte(3)
      ..write(obj.progressInSeconds)
      ..writeByte(4)
      ..write(obj.durationInSeconds)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.watchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
