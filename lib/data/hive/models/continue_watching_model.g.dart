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
      episodeTitle: fields[2] as String?,
      episodeNumber: fields[3] as int?,
      episodeThumbnail: fields[4] as String?,
      animeCover: fields[5] as String?,
      totalEpisodes: fields[6] as int?,
      progressInSeconds: fields[7] as int?,
      durationInSeconds: fields[8] as int?,
      lastUpdated: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ContinueWatchingEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.animeId)
      ..writeByte(1)
      ..write(obj.animeTitle)
      ..writeByte(2)
      ..write(obj.episodeTitle)
      ..writeByte(3)
      ..write(obj.episodeNumber)
      ..writeByte(4)
      ..write(obj.episodeThumbnail)
      ..writeByte(5)
      ..write(obj.animeCover)
      ..writeByte(6)
      ..write(obj.totalEpisodes)
      ..writeByte(7)
      ..write(obj.progressInSeconds)
      ..writeByte(8)
      ..write(obj.durationInSeconds)
      ..writeByte(9)
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
