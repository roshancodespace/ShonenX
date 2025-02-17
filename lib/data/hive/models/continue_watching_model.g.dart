// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'continue_watching_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContinueWatchingEntryAdapter extends TypeAdapter<ContinueWatchingEntry> {
  @override
  final int typeId = 5;

  @override
  ContinueWatchingEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContinueWatchingEntry(
      animeId: fields[0] as int?,
      animeTitle: fields[1] as String?,
      animeFormat: fields[2] as String?,
      episodeTitle: fields[3] as String?,
      episodeNumber: fields[4] as int?,
      episodeThumbnail: fields[5] as String?,
      animeCover: fields[6] as String?,
      totalEpisodes: fields[7] as int?,
      progressInSeconds: fields[8] as int?,
      durationInSeconds: fields[9] as int?,
      lastUpdated: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ContinueWatchingEntry obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.animeId)
      ..writeByte(1)
      ..write(obj.animeTitle)
      ..writeByte(2)
      ..write(obj.animeFormat)
      ..writeByte(3)
      ..write(obj.episodeTitle)
      ..writeByte(4)
      ..write(obj.episodeNumber)
      ..writeByte(5)
      ..write(obj.episodeThumbnail)
      ..writeByte(6)
      ..write(obj.animeCover)
      ..writeByte(7)
      ..write(obj.totalEpisodes)
      ..writeByte(8)
      ..write(obj.progressInSeconds)
      ..writeByte(9)
      ..write(obj.durationInSeconds)
      ..writeByte(10)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContinueWatchingEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
