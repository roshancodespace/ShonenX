// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_offline_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 1;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      providerSettings: fields[0] as ProviderSettingsModel,
      themeSettings: fields[1] as ThemeSettingsModel,
      playerSettings: fields[2] as PlayerSettingsModel,
      uiSettings: fields[3] as UISettingsModel?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.providerSettings)
      ..writeByte(1)
      ..write(obj.themeSettings)
      ..writeByte(2)
      ..write(obj.playerSettings)
      ..writeByte(3)
      ..write(obj.uiSettings);
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
  final int typeId = 2;

  @override
  ProviderSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProviderSettingsModel(
      selectedProviderName: fields[0] as String,
      customApiUrl: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProviderSettingsModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.selectedProviderName)
      ..writeByte(1)
      ..write(obj.customApiUrl);
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

class ThemeSettingsModelAdapter extends TypeAdapter<ThemeSettingsModel> {
  @override
  final int typeId = 3;

  @override
  ThemeSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThemeSettingsModel(
      themeMode: fields[0] as String,
      amoled: fields[1] as bool,
      colorScheme: fields[2] as String,
      useMaterial3: fields[3] as bool,
      useSubThemes: fields[4] as bool,
      surfaceModeLight: fields[5] as double,
      surfaceModeDark: fields[6] as double,
      useKeyColors: fields[7] as bool,
      useAppbarColors: fields[8] as bool,
      swapLightColors: fields[9] as bool,
      swapDarkColors: fields[10] as bool,
      useTertiary: fields[11] as bool,
      blendLevel: fields[12] as int,
      appBarOpacity: fields[13] as double,
      transparentStatusBar: fields[14] as bool,
      tabBarOpacity: fields[15] as double,
      bottomBarOpacity: fields[16] as double,
      tooltipsMatchBackground: fields[17] as bool,
      defaultRadius: fields[18] as double,
      useTextTheme: fields[19] as bool,
      tabBarStyle: fields[20] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ThemeSettingsModel obj) {
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
      other is ThemeSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AnilistSettingsAdapter extends TypeAdapter<AnilistSettings> {
  @override
  final int typeId = 4;

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
  final int typeId = 5;

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
      subtitleFontSize: fields[3] as double,
      subtitleTextColor: fields[4] as int,
      subtitleBackgroundOpacity: fields[5] as double,
      subtitleHasShadow: fields[6] as bool,
      defaultPlaybackSpeed: fields.containsKey(7) ? fields[7] as double : 1.0,
      skipIntro: fields.containsKey(8) ? fields[8] as bool : true,
      skipOutro: fields.containsKey(9) ? fields[9] as bool : true,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerSettingsModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.episodeCompletionThreshold)
      ..writeByte(1)
      ..write(obj.autoPlayNextEpisode)
      ..writeByte(2)
      ..write(obj.preferSubtitles)
      ..writeByte(3)
      ..write(obj.subtitleFontSize)
      ..writeByte(4)
      ..write(obj.subtitleTextColor)
      ..writeByte(5)
      ..write(obj.subtitleBackgroundOpacity)
      ..writeByte(6)
      ..write(obj.subtitleHasShadow)
      ..writeByte(7)
      ..write(obj.defaultPlaybackSpeed)
      ..writeByte(8)
      ..write(obj.skipIntro)
      ..writeByte(9)
      ..write(obj.skipOutro);
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

class UISettingsModelAdapter extends TypeAdapter<UISettingsModel> {
  @override
  final int typeId = 6;

  @override
  UISettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UISettingsModel(
      compactMode: fields[0] as bool,
      defaultTab: fields[1] as String,
      showThumbnails: fields[2] as bool,
      cardStyle: fields[3] as String,
      layoutStyle: fields[4] as String,
      immersiveMode: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UISettingsModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.compactMode)
      ..writeByte(1)
      ..write(obj.defaultTab)
      ..writeByte(2)
      ..write(obj.showThumbnails)
      ..writeByte(3)
      ..write(obj.cardStyle)
      ..writeByte(4)
      ..write(obj.layoutStyle)
      ..writeByte(5)
      ..write(obj.immersiveMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UISettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
