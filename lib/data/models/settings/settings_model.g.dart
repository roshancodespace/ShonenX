// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 0;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      defaultQuality: fields[0] as String?,
      theme: fields[1] as String?,
      defaultOrientation: fields[2] as String?,
      layoutMode: fields[3] as String?,
      isLabelEnabled: fields[4] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.defaultQuality)
      ..writeByte(1)
      ..write(obj.theme)
      ..writeByte(2)
      ..write(obj.defaultOrientation)
      ..writeByte(3)
      ..write(obj.layoutMode)
      ..writeByte(4)
      ..write(obj.isLabelEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
