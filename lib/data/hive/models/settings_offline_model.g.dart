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
      providerSettings: (fields.containsKey(0) && fields[0] != null)
          ? fields[0] as ProviderSettingsModel
          : ProviderSettingsModel(),
      appearanceSettings: (fields.containsKey(1) && fields[1] != null)
          ? fields[1] as AppearanceSettingsModel
          : AppearanceSettingsModel(),
      playerSettings: (fields.containsKey(2) && fields[2] != null)
          ? fields[2] as PlayerSettingsModel
          : PlayerSettingsModel(),
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
      selectedProviderName: (fields.containsKey(0) && fields[0] != null)
          ? fields[0] as String
          : 'hianime',
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
      themeMode: (fields.containsKey(0) && fields[0] != null)
          ? fields[0] as String
          : 'system',
      amoled: (fields.containsKey(1) && fields[1] != null)
          ? fields[1] as bool
          : false,
      colorScheme: (fields.containsKey(2) && fields[2] != null)
          ? fields[2] as String
          : 'red',
      useMaterial3: (fields.containsKey(3) && fields[3] != null)
          ? fields[3] as bool
          : true,
      useSubThemes: (fields.containsKey(4) && fields[4] != null)
          ? fields[4] as bool
          : true,
      surfaceModeLight: (fields.containsKey(5) && fields[5] != null)
          ? fields[5] as double
          : 0.0,
      surfaceModeDark: (fields.containsKey(6) && fields[6] != null)
          ? fields[6] as double
          : 0.0,
      useKeyColors: (fields.containsKey(7) && fields[7] != null)
          ? fields[7] as bool
          : true,
      useAppbarColors: (fields.containsKey(8) && fields[8] != null)
          ? fields[8] as bool
          : false,
      swapLightColors: (fields.containsKey(9) && fields[9] != null)
          ? fields[9] as bool
          : false,
      swapDarkColors: (fields.containsKey(10) && fields[10] != null)
          ? fields[10] as bool
          : false,
      useTertiary: (fields.containsKey(11) && fields[11] != null)
          ? fields[11] as bool
          : true,
      blendLevel: (fields.containsKey(12) && fields[12] != null)
          ? fields[12] as int
          : 0,
      appBarOpacity: (fields.containsKey(13) && fields[13] != null)
          ? fields[13] as double
          : 1.0,
      transparentStatusBar: (fields.containsKey(14) && fields[14] != null)
          ? fields[14] as bool
          : false,
      tabBarOpacity: (fields.containsKey(15) && fields[15] != null)
          ? fields[15] as double
          : 1.0,
      bottomBarOpacity: (fields.containsKey(16) && fields[16] != null)
          ? fields[16] as double
          : 1.0,
      tooltipsMatchBackground: (fields.containsKey(17) && fields[17] != null)
          ? fields[17] as bool
          : false,
      defaultRadius: (fields.containsKey(18) && fields[18] != null)
          ? fields[18] as double
          : 12.0,
      useTextTheme: (fields.containsKey(19) && fields[19] != null)
          ? fields[19] as bool
          : true,
      tabBarStyle: (fields.containsKey(20) && fields[20] != null)
          ? fields[20] as String
          : 'forBackground',
    );
  }

  @override
  void write(BinaryWriter writer, AppearanceSettingsModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.amoled)
      ..writeByte(2)
      ..write(obj.colorScheme)
      ..writeByte(3)
      ..write(obj.useMaterial3)
      ..writeByte(4)
      ..write(obj.useSubThemes)
      ..writeByte(5)
      ..write(obj.surfaceModeLight)
      ..writeByte(6)
      ..write(obj.surfaceModeDark)
      ..writeByte(7)
      ..write(obj.useKeyColors)
      ..writeByte(8)
      ..write(obj.useAppbarColors)
      ..writeByte(9)
      ..write(obj.swapLightColors)
      ..writeByte(10)
      ..write(obj.swapDarkColors)
      ..writeByte(11)
      ..write(obj.useTertiary)
      ..writeByte(12)
      ..write(obj.blendLevel)
      ..writeByte(13)
      ..write(obj.appBarOpacity)
      ..writeByte(14)
      ..write(obj.transparentStatusBar)
      ..writeByte(15)
      ..write(obj.tabBarOpacity)
      ..writeByte(16)
      ..write(obj.bottomBarOpacity)
      ..writeByte(17)
      ..write(obj.tooltipsMatchBackground)
      ..writeByte(18)
      ..write(obj.defaultRadius)
      ..writeByte(19)
      ..write(obj.useTextTheme)
      ..writeByte(20)
      ..write(obj.tabBarStyle);
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
