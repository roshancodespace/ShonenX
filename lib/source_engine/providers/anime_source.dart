import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';

abstract class AnimeSource {
  SourceInfo get sourceInfo;

  Future<List<SourceSetting>> getSettingsSchema() async => const [
    // SourceSetting(
    //   id: 'use_proxy',
    //   name: 'Use Proxy',
    //   description: 'Enable proxy for bypassing region blocks',
    //   type: SettingType.boolean,
    //   defaultValue: false,
    // ),
    // SourceSetting(
    //   id: 'preferred_quality',
    //   name: 'Preferred Quality',
    //   description: 'Default video quality to select',
    //   type: SettingType.select,
    //   options: ['Auto', '1080p', '720p', '480p'],
    //   defaultValue: 'Auto',
    // ),
    // SourceSetting(
    //   id: 'language_preference',
    //   name: 'Language Preference',
    //   description: 'Select available audio tracks to fetch',
    //   type: SettingType.multiSelect,
    //   options: ['Sub', 'Dub', 'Raw'],
    //   defaultValue: <String>['Sub', 'Dub', 'Raw'],
    // ),
  ];

  Future<List<UnifiedMedia>> search(
    String query,
    MediaType type, {
    int page = 1,
    bool isAdult = false,
    List<String> sort = const ['SEARCH_MATCH'],
  });

  Future<List<UnifiedMedia>> getTrending({int page = 1});

  Future<UnifiedMedia> getDetails(String providerId, MediaType type);
  Future<List<UnifiedEpisode>> getEpisodes(String animeId);
  Future<List<VideoServer>> getServers(String episodeId);
  Future<List<VideoStream>> getSources(String episodeId, VideoServer server);

  @override
  int get hashCode => sourceInfo.id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimeSource &&
        other.sourceInfo.id == sourceInfo.id &&
        other.sourceInfo.name == sourceInfo.name &&
        other.sourceInfo.type == sourceInfo.type;
  }
}
