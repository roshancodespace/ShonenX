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
      playerSettings: fields[2] as PlayerSettingsModel?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.providerSettings)
      ..writeByte(1)
      ..write(obj.appearanceSettings)
      ..writeByte(2)
      ..write(obj.playerSettings);
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
      amoled: fields[1] as bool,
      colorScheme: fields[2] as FlexScheme,
    );
  }

  @override
  void write(BinaryWriter writer, AppearanceSettingsModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.amoled)
      ..writeByte(2)
      ..write(obj.colorScheme);
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

class PlayerSettingsModelAdapter extends TypeAdapter<PlayerSettingsModel> {
  @override
  final int typeId = 4;

  @override
  PlayerSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerSettingsModel(
      episodeCompletionThreshold: fields[0] as double,
      autoPlayNextEpisode: fields[1] as bool,
      preferSubtitles: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerSettingsModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.episodeCompletionThreshold)
      ..writeByte(1)
      ..write(obj.autoPlayNextEpisode)
      ..writeByte(2)
      ..write(obj.preferSubtitles);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
