// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UiModelAdapter extends TypeAdapter<UiModel> {
  @override
  final int typeId = 3;

  @override
  UiModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UiModel(
      cardStyle: fields[3] == null ? 'defaults' : fields[3] as String,
      spotlightCardStyle: fields[2] == null ? 'defaults' : fields[2] as String,
      immersiveMode: fields[5] == null ? false : fields[5] as bool,
      episodeViewMode: fields[6] == null ? 'list' : fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UiModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(2)
      ..write(obj.spotlightCardStyle)
      ..writeByte(3)
      ..write(obj.cardStyle)
      ..writeByte(5)
      ..write(obj.immersiveMode)
      ..writeByte(6)
      ..write(obj.episodeViewMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
