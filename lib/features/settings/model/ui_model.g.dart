// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UiModelAdapter extends TypeAdapter<UiModel> {
  @override
  final typeId = 3;

  @override
  UiModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UiModel(
      cardStyle: fields[2] == null ? 'defaults' : fields[2] as String,
      immersiveMode: fields[5] == null ? false : fields[5] as bool,
      spotlightCardStyle: fields[3] == null ? 'defaults' : fields[3] as String,
      episodeViewMode: fields[6] == null ? 'list' : fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UiModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(2)
      ..write(obj.cardStyle)
      ..writeByte(3)
      ..write(obj.spotlightCardStyle)
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
