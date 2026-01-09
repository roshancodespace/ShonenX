// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContentSettingsModelAdapter extends TypeAdapter<ContentSettingsModel> {
  @override
  final int typeId = 15;

  @override
  ContentSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContentSettingsModel(
      showAnilistAdult: fields[0] == null ? false : fields[0] as bool,
      showMalAdult: fields[1] == null ? false : fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ContentSettingsModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.showAnilistAdult)
      ..writeByte(1)
      ..write(obj.showMalAdult);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
