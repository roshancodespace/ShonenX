// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerModelAdapter extends TypeAdapter<PlayerModel> {
  @override
  final typeId = 4;

  @override
  PlayerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerModel(
      defaultQuality: fields[0] == null ? 'Auto' : fields[0] as String,
      enableAniSkip: fields[1] == null ? true : fields[1] as bool,
      enableAutoSkip: fields[2] == null ? false : fields[2] as bool,
      preferDub: fields[3] == null ? false : fields[3] as bool,
      seekDuration: fields[4] == null ? 10 : fields[4] as int,
      autoHideDuration: fields[5] == null ? 4 : fields[5] as int,
      showNextPrevButtons: fields[6] == null ? true : fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.defaultQuality)
      ..writeByte(1)
      ..write(obj.enableAniSkip)
      ..writeByte(2)
      ..write(obj.enableAutoSkip)
      ..writeByte(3)
      ..write(obj.preferDub)
      ..writeByte(4)
      ..write(obj.seekDuration)
      ..writeByte(5)
      ..write(obj.autoHideDuration)
      ..writeByte(6)
      ..write(obj.showNextPrevButtons);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
