// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class ThemeModelAdapter extends TypeAdapter<ThemeModel> {
  @override
  final typeId = 2;

  @override
  ThemeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThemeModel(
      themeMode: fields[0] == null ? 'system' : fields[0] as String,
      amoled: fields[1] == null ? false : fields[1] as bool,
      flexScheme: fields[2] as String?,
      blendLevel: fields[3] == null ? 11 : (fields[3] as num).toInt(),
      swapColors: fields[4] == null ? false : fields[4] as bool,
      useMaterial3: fields[5] == null ? true : fields[5] as bool,
      useDynamicColors: fields[6] == null ? false : fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ThemeModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.amoled)
      ..writeByte(2)
      ..write(obj.flexScheme)
      ..writeByte(3)
      ..write(obj.blendLevel)
      ..writeByte(4)
      ..write(obj.swapColors)
      ..writeByte(5)
      ..write(obj.useMaterial3)
      ..writeByte(6)
      ..write(obj.useDynamicColors);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
      seekDuration: fields[4] == null ? 10 : (fields[4] as num).toInt(),
      autoHideDuration: fields[5] == null ? 4 : (fields[5] as num).toInt(),
      showNextPrevButtons: fields[6] == null ? true : fields[6] as bool,
      mpvSettings: fields[7] == null
          ? const {}
          : (fields[7] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PlayerModel obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.showNextPrevButtons)
      ..writeByte(7)
      ..write(obj.mpvSettings);
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

class HomePageModelAdapter extends TypeAdapter<HomePageModel> {
  @override
  final typeId = 5;

  @override
  HomePageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HomePageModel(
      sections: (fields[0] as Map).map(
        (dynamic k, dynamic v) => MapEntry(
          k as String,
          (v as List).map((e) => (e as Map).cast<String, dynamic>()).toList(),
        ),
      ),
      lastUpdated: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HomePageModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.sections)
      ..writeByte(1)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomePageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AnimeWatchProgressEntryAdapter
    extends TypeAdapter<AnimeWatchProgressEntry> {
  @override
  final typeId = 7;

  @override
  AnimeWatchProgressEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnimeWatchProgressEntry(
      animeId: fields[0] as String,
      animeTitle: fields[1] as String,
      animeFormat: fields[2] as String,
      animeCover: fields[3] as String,
      totalEpisodes: (fields[4] as num).toInt(),
      episodesProgress: fields[5] == null
          ? const {}
          : (fields[5] as Map).cast<int, EpisodeProgress>(),
      lastUpdated: fields[6] as DateTime?,
      currentEpisode: fields[7] == null ? 1 : (fields[7] as num).toInt(),
      status: fields[8] == null ? 'watching' : fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AnimeWatchProgressEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.animeId)
      ..writeByte(1)
      ..write(obj.animeTitle)
      ..writeByte(2)
      ..write(obj.animeFormat)
      ..writeByte(3)
      ..write(obj.animeCover)
      ..writeByte(4)
      ..write(obj.totalEpisodes)
      ..writeByte(5)
      ..write(obj.episodesProgress)
      ..writeByte(6)
      ..write(obj.lastUpdated)
      ..writeByte(7)
      ..write(obj.currentEpisode)
      ..writeByte(8)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimeWatchProgressEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EpisodeProgressAdapter extends TypeAdapter<EpisodeProgress> {
  @override
  final typeId = 8;

  @override
  EpisodeProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EpisodeProgress(
      episodeNumber: (fields[0] as num).toInt(),
      episodeTitle: fields[1] as String,
      episodeThumbnail: fields[2] as String?,
      progressInSeconds: (fields[3] as num?)?.toInt(),
      durationInSeconds: (fields[4] as num?)?.toInt(),
      isCompleted: fields[5] == null ? false : fields[5] as bool,
      watchedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, EpisodeProgress obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.episodeNumber)
      ..writeByte(1)
      ..write(obj.episodeTitle)
      ..writeByte(2)
      ..write(obj.episodeThumbnail)
      ..writeByte(3)
      ..write(obj.progressInSeconds)
      ..writeByte(4)
      ..write(obj.durationInSeconds)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.watchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubtitleAppearanceModelAdapter
    extends TypeAdapter<SubtitleAppearanceModel> {
  @override
  final typeId = 10;

  @override
  SubtitleAppearanceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubtitleAppearanceModel(
      fontSize: fields[0] == null ? 16.0 : (fields[0] as num).toDouble(),
      textColor: fields[1] == null ? 0xFFFFFFFF : (fields[1] as num).toInt(),
      backgroundOpacity: fields[2] == null
          ? 0.5
          : (fields[2] as num).toDouble(),
      hasShadow: fields[3] == null ? true : fields[3] as bool,
      shadowOpacity: fields[4] == null ? 0.5 : (fields[4] as num).toDouble(),
      shadowBlur: fields[5] == null ? 2.0 : (fields[5] as num).toDouble(),
      fontFamily: fields[6] as String?,
      position: fields[7] == null ? 1 : (fields[7] as num).toInt(),
      boldText: fields[8] == null ? true : fields[8] as bool,
      forceUppercase: fields[9] == null ? false : fields[9] as bool,
      bottomMargin: fields[10] == null ? 20.0 : (fields[10] as num).toDouble(),
      backgroundColor: fields[11] == null
          ? 0xFF000000
          : (fields[11] as num).toInt(),
      outlineColor: fields[12] == null
          ? 0xFF000000
          : (fields[12] as num).toInt(),
      outlineWidth: fields[13] == null ? 0.0 : (fields[13] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, SubtitleAppearanceModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.fontSize)
      ..writeByte(1)
      ..write(obj.textColor)
      ..writeByte(2)
      ..write(obj.backgroundOpacity)
      ..writeByte(3)
      ..write(obj.hasShadow)
      ..writeByte(4)
      ..write(obj.shadowOpacity)
      ..writeByte(5)
      ..write(obj.shadowBlur)
      ..writeByte(6)
      ..write(obj.fontFamily)
      ..writeByte(7)
      ..write(obj.position)
      ..writeByte(8)
      ..write(obj.boldText)
      ..writeByte(9)
      ..write(obj.forceUppercase)
      ..writeByte(10)
      ..write(obj.bottomMargin)
      ..writeByte(11)
      ..write(obj.backgroundColor)
      ..writeByte(12)
      ..write(obj.outlineColor)
      ..writeByte(13)
      ..write(obj.outlineWidth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubtitleAppearanceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExperimentalFeaturesModelAdapter
    extends TypeAdapter<ExperimentalFeaturesModel> {
  @override
  final typeId = 11;

  @override
  ExperimentalFeaturesModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExperimentalFeaturesModel(
      episodeTitleSync: fields[0] == null ? false : fields[0] as bool,
      useMangayomiExtensions: fields[1] == null ? false : fields[1] as bool,
      useTestReleases: fields[2] == null ? false : fields[2] as bool,
      newUI: fields[3] == null ? false : fields[3] as bool,
      debugMode: fields[4] == null ? false : fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ExperimentalFeaturesModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.episodeTitleSync)
      ..writeByte(1)
      ..write(obj.useMangayomiExtensions)
      ..writeByte(2)
      ..write(obj.useTestReleases)
      ..writeByte(3)
      ..write(obj.newUI)
      ..writeByte(4)
      ..write(obj.debugMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExperimentalFeaturesModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadItemAdapter extends TypeAdapter<DownloadItem> {
  @override
  final typeId = 12;

  @override
  DownloadItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadItem(
      id: fields[0] as String?,
      quality: fields[9] == null ? 'Default' : fields[9] as String,
      downloadUrl: fields[8] as String,
      animeTitle: fields[1] as String,
      episodeTitle: fields[2] as String,
      episodeNumber: (fields[3] as num).toInt(),
      thumbnail: fields[4] as String,
      size: (fields[5] as num?)?.toInt(),
      state: fields[6] as DownloadStatus,
      progress: (fields[7] as num).toInt(),
      filePath: fields[10] as String,
      headers: fields[11] == null
          ? const {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            }
          : (fields[11] as Map).cast<dynamic, dynamic>(),
      speed: fields[15] == null ? 0 : (fields[15] as num).toInt(),
      eta: fields[16] as Duration?,
      contentType: fields[12] as String?,
      error: fields[17] as dynamic,
      subtitles: (fields[13] as List?)?.cast<dynamic>(),
      totalSegments: (fields[14] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, DownloadItem obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.animeTitle)
      ..writeByte(2)
      ..write(obj.episodeTitle)
      ..writeByte(3)
      ..write(obj.episodeNumber)
      ..writeByte(4)
      ..write(obj.thumbnail)
      ..writeByte(5)
      ..write(obj.size)
      ..writeByte(6)
      ..write(obj.state)
      ..writeByte(7)
      ..write(obj.progress)
      ..writeByte(8)
      ..write(obj.downloadUrl)
      ..writeByte(9)
      ..write(obj.quality)
      ..writeByte(10)
      ..write(obj.filePath)
      ..writeByte(11)
      ..write(obj.headers)
      ..writeByte(12)
      ..write(obj.contentType)
      ..writeByte(13)
      ..write(obj.subtitles)
      ..writeByte(14)
      ..write(obj.totalSegments)
      ..writeByte(15)
      ..write(obj.speed)
      ..writeByte(16)
      ..write(obj.eta)
      ..writeByte(17)
      ..write(obj.error);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadStatusAdapter extends TypeAdapter<DownloadStatus> {
  @override
  final typeId = 13;

  @override
  DownloadStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DownloadStatus.downloaded;
      case 1:
        return DownloadStatus.downloading;
      case 2:
        return DownloadStatus.paused;
      case 3:
        return DownloadStatus.error;
      case 4:
        return DownloadStatus.queued;
      case 5:
        return DownloadStatus.failed;
      default:
        return DownloadStatus.downloaded;
    }
  }

  @override
  void write(BinaryWriter writer, DownloadStatus obj) {
    switch (obj) {
      case DownloadStatus.downloaded:
        writer.writeByte(0);
      case DownloadStatus.downloading:
        writer.writeByte(1);
      case DownloadStatus.paused:
        writer.writeByte(2);
      case DownloadStatus.error:
        writer.writeByte(3);
      case DownloadStatus.queued:
        writer.writeByte(4);
      case DownloadStatus.failed:
        writer.writeByte(5);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadSettingsModelAdapter extends TypeAdapter<DownloadSettingsModel> {
  @override
  final typeId = 14;

  @override
  DownloadSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadSettingsModel(
      customDownloadPath: fields[0] as String?,
      useCustomPath: fields[1] == null ? false : fields[1] as bool,
      folderStructure: fields[2] == null
          ? 'Anime/Episode'
          : fields[2] as String,
      parallelDownloads: fields[3] == null ? 5 : (fields[3] as num).toInt(),
      speedLimitKBps: fields[4] == null ? 0 : (fields[4] as num).toInt(),
      wifiOnly: fields[5] == null ? false : fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadSettingsModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.customDownloadPath)
      ..writeByte(1)
      ..write(obj.useCustomPath)
      ..writeByte(2)
      ..write(obj.folderStructure)
      ..writeByte(3)
      ..write(obj.parallelDownloads)
      ..writeByte(4)
      ..write(obj.speedLimitKBps)
      ..writeByte(5)
      ..write(obj.wifiOnly);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContentSettingsModelAdapter extends TypeAdapter<ContentSettingsModel> {
  @override
  final typeId = 15;

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

class UniversalNewsAdapter extends TypeAdapter<UniversalNews> {
  @override
  final typeId = 16;

  @override
  UniversalNews read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UniversalNews(
      title: fields[0] as String?,
      url: fields[1] as String?,
      imageUrl: fields[2] as String?,
      date: fields[3] as String?,
      excerpt: fields[4] as String?,
      body: fields[5] as String?,
      isRead: fields[6] == null ? false : fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UniversalNews obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.imageUrl)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.excerpt)
      ..writeByte(5)
      ..write(obj.body)
      ..writeByte(6)
      ..write(obj.isRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniversalNewsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AnimeCardModeAdapter extends TypeAdapter<AnimeCardMode> {
  @override
  final typeId = 17;

  @override
  AnimeCardMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AnimeCardMode.defaults;
      case 1:
        return AnimeCardMode.minimal;
      case 2:
        return AnimeCardMode.classic;
      case 3:
        return AnimeCardMode.coverOnly;
      case 4:
        return AnimeCardMode.liquidGlass;
      case 5:
        return AnimeCardMode.neon;
      case 6:
        return AnimeCardMode.manga;
      case 7:
        return AnimeCardMode.compact;
      case 8:
        return AnimeCardMode.polaroid;
      default:
        return AnimeCardMode.defaults;
    }
  }

  @override
  void write(BinaryWriter writer, AnimeCardMode obj) {
    switch (obj) {
      case AnimeCardMode.defaults:
        writer.writeByte(0);
      case AnimeCardMode.minimal:
        writer.writeByte(1);
      case AnimeCardMode.classic:
        writer.writeByte(2);
      case AnimeCardMode.coverOnly:
        writer.writeByte(3);
      case AnimeCardMode.liquidGlass:
        writer.writeByte(4);
      case AnimeCardMode.neon:
        writer.writeByte(5);
      case AnimeCardMode.manga:
        writer.writeByte(6);
      case AnimeCardMode.compact:
        writer.writeByte(7);
      case AnimeCardMode.polaroid:
        writer.writeByte(8);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimeCardModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SpotlightCardModeAdapter extends TypeAdapter<SpotlightCardMode> {
  @override
  final typeId = 18;

  @override
  SpotlightCardMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SpotlightCardMode.defaults;
      case 1:
        return SpotlightCardMode.minimal;
      case 2:
        return SpotlightCardMode.classic;
      case 3:
        return SpotlightCardMode.coverOnly;
      case 4:
        return SpotlightCardMode.liquidGlass;
      case 5:
        return SpotlightCardMode.neon;
      case 6:
        return SpotlightCardMode.manga;
      case 7:
        return SpotlightCardMode.compact;
      case 8:
        return SpotlightCardMode.polaroid;
      default:
        return SpotlightCardMode.defaults;
    }
  }

  @override
  void write(BinaryWriter writer, SpotlightCardMode obj) {
    switch (obj) {
      case SpotlightCardMode.defaults:
        writer.writeByte(0);
      case SpotlightCardMode.minimal:
        writer.writeByte(1);
      case SpotlightCardMode.classic:
        writer.writeByte(2);
      case SpotlightCardMode.coverOnly:
        writer.writeByte(3);
      case SpotlightCardMode.liquidGlass:
        writer.writeByte(4);
      case SpotlightCardMode.neon:
        writer.writeByte(5);
      case SpotlightCardMode.manga:
        writer.writeByte(6);
      case SpotlightCardMode.compact:
        writer.writeByte(7);
      case SpotlightCardMode.polaroid:
        writer.writeByte(8);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotlightCardModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UiSettingsAdapter extends TypeAdapter<UiSettings> {
  @override
  final typeId = 19;

  @override
  UiSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UiSettings(
      cardStyle: fields[0] == null
          ? AnimeCardMode.defaults
          : fields[0] as AnimeCardMode,
      immersiveMode: fields[2] == null ? false : fields[2] as bool,
      spotlightCardStyle: fields[1] == null
          ? SpotlightCardMode.defaults
          : fields[1] as SpotlightCardMode,
      episodeViewMode: fields[3] == null ? 'list' : fields[3] as String,
      scale: fields[4] == null ? 1.0 : (fields[4] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, UiSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.cardStyle)
      ..writeByte(1)
      ..write(obj.spotlightCardStyle)
      ..writeByte(2)
      ..write(obj.immersiveMode)
      ..writeByte(3)
      ..write(obj.episodeViewMode)
      ..writeByte(4)
      ..write(obj.scale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
