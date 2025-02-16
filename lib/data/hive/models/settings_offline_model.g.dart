// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_offline_model.dart';

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
      providerSettings: fields[0] as ProviderSettingsModel?,
      appearanceSettings: fields[1] as AppearanceSettingsModel?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.providerSettings)
      ..writeByte(1)
      ..write(obj.appearanceSettings);
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

class ProviderSettingsModelAdapter extends TypeAdapter<ProviderSettingsModel> {
  @override
  final int typeId = 1;

  @override
  ProviderSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProviderSettingsModel(
      selectedProviderName: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProviderSettingsModel obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.selectedProviderName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppearanceSettingsModelAdapter
    extends TypeAdapter<AppearanceSettingsModel> {
  @override
  final int typeId = 2;

  @override
  AppearanceSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppearanceSettingsModel(
      themeMode: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppearanceSettingsModel obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.themeMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppearanceSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AnilistSettingsAdapter extends TypeAdapter<AnilistSettings> {
  @override
  final int typeId = 3;

  @override
  AnilistSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnilistSettings(
      themeMode: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AnilistSettings obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.themeMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnilistSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
