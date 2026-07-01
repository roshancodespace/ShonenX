import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';

abstract class MediaSource {
  SourceInfo get sourceInfo;

  Future<List<SourceSetting>> getSettingsSchema() async => const [];

  Future<List<String>> getFilterGenres() async => const [];

  Future<List<String>> getFilterTags() async => const [];

  Future<List<UnifiedMedia>> search(
    String query,
    MediaType type, {
    int page = 1,
    bool isAdult = false,
    List<String> sort = const ['SEARCH_MATCH'],
    List<String> genres = const [],
    List<String> tags = const [],
  });

  Future<List<UnifiedMedia>> getTrending({int page = 1});

  Future<UnifiedMedia> getDetails(String providerId, MediaType type);

  @override
  int get hashCode => sourceInfo.id.hashCode ^ sourceInfo.mediaType.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaSource &&
        other.sourceInfo.id == sourceInfo.id &&
        other.sourceInfo.name == sourceInfo.name &&
        other.sourceInfo.type == sourceInfo.type &&
        other.sourceInfo.mediaType == sourceInfo.mediaType;
  }
}
