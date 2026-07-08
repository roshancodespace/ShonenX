import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/source_engine/providers/media_source.dart';

abstract class BaseSourceAdapter implements MediaSource {
  @override
  final SourceInfo sourceInfo;
  final bridge.Source source;

  BaseSourceAdapter({required this.sourceInfo, required this.source});

  ScopedLogger get log;

  MediaType get mediaType => sourceInfo.mediaType;

  @override
  Future<List<SourceSetting>> getSettingsSchema() async {
    final methodLog = log.child('getSettingsSchema');
    try {
      final schema = await source.methods.getPreference();
      final List<SourceSetting> settings = [];

      for (final pref in schema) {
        if (pref.key == null || pref.type == null) continue;

        try {
          if (pref.type == 'switch' || pref.type == 'checkbox') {
            final title =
                pref.switchPreferenceCompat?.title ??
                pref.checkBoxPreference?.title ??
                pref.key!;
            final description =
                pref.switchPreferenceCompat?.summary ??
                pref.checkBoxPreference?.summary ??
                '';
            final defaultValue =
                pref.switchPreferenceCompat?.value ??
                pref.checkBoxPreference?.value ??
                false;

            settings.add(
              SourceSetting(
                id: pref.key!,
                name: title,
                description: description,
                type: SettingType.boolean,
                defaultValue: defaultValue,
              ),
            );
          } else if (pref.type == 'list') {
            final listPref = pref.listPreference;
            final options = listPref?.entryValues ?? listPref?.entries ?? [];

            settings.add(
              SourceSetting(
                id: pref.key!,
                name: listPref?.title ?? pref.key!,
                description: listPref?.summary ?? '',
                type: SettingType.select,
                defaultValue:
                    listPref?.value ??
                    (options.isNotEmpty ? options.first : ''),
                options: options,
              ),
            );
          } else if (pref.type == 'multi_select') {
            final multiPref = pref.multiSelectListPreference;
            final options = multiPref?.entryValues ?? multiPref?.entries ?? [];

            settings.add(
              SourceSetting(
                id: pref.key!,
                name: multiPref?.title ?? pref.key!,
                description: multiPref?.summary ?? '',
                type: SettingType.multiSelect,
                defaultValue: multiPref?.values ?? [],
                options: options,
              ),
            );
          } else if (pref.type == 'text') {
            final textPref = pref.editTextPreference;
            settings.add(
              SourceSetting(
                id: pref.key!,
                name: textPref?.title ?? pref.key!,
                description: textPref?.summary ?? '',
                type: SettingType.text,
                defaultValue: textPref?.value ?? '',
              ),
            );
          } else {
            methodLog.w('Unsupported setting type: ${pref.type}');
          }
        } catch (e) {
          methodLog.e('Failed to parse setting ${pref.key}', e);
        }
      }

      return settings;
    } catch (e, st) {
      methodLog.e('Failed to fetch settings schema', e, st);
      return [];
    }
  }

  @override
  Future<List<UnifiedMedia>> search(
    String query,
    MediaType type, {
    int page = 1,
    bool isAdult = false,
    List<String> sort = const ['SEARCH_MATCH'],
    List<String> genres = const [],
    List<String> tags = const [],
  }) async {
    final methodLog = log.child('search');
    try {
      methodLog.i('query=$query page=$page genres=$genres tags=$tags');
      final results = await source.methods.search(query, page, [...genres, ...tags]);
      methodLog.d('results=${results.list.length}');

      return results.list
          .map(
            (e) => UnifiedMedia(
              id: '${e.url!}|${e.title!}',
              type: mediaType,
              sourceId: sourceInfo.id,
              sourceName: sourceInfo.name,
              providerId: e.url!,
              title: MediaTitle(english: e.title),
              cover: e.cover,
              description: e.description,
            ),
          )
          .toList();
    } catch (e, st) {
      methodLog.e('search failed', e, st);
      return [];
    }
  }

  @override
  Future<List<UnifiedMedia>> getTrending({int page = 1}) async {
    final methodLog = log.child('getTrending');
    try {
      methodLog.i('page=$page');
      final results = await source.methods.getPopular(page);
      methodLog.d('results=${results.list.length}');

      final list = results.list
          .map(
            (e) => UnifiedMedia(
              id: '${e.url!}|${e.title!}',
              type: mediaType,
              sourceId: sourceInfo.id,
              sourceName: sourceInfo.name,
              providerId: e.url!,
              title: MediaTitle(english: e.title),
              cover: e.cover,
              description: e.description,
            ),
          )
          .toList();

      if (list.isNotEmpty) return list;
      methodLog.i('getTrending returned empty, falling back to search("")');
      return await search('', mediaType, page: page);
    } catch (e, st) {
      methodLog.e('getTrending failed, falling back to search("")', e, st);
      try {
        return await search('', mediaType, page: page);
      } catch (_) {
        return [];
      }
    }
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) async {
    final methodLog = log.child('getDetails');
    try {
      final parts = providerId.split('|');
      methodLog.i('url=${parts[0]} title=${parts.length > 1 ? parts[1] : ''}');

      final detail = await source.methods.getDetail(
        bridge.DMedia(url: parts[0], title: parts.length > 1 ? parts[1] : ''),
      );

      return UnifiedMedia(
        id: providerId,
        type: mediaType,
        sourceId: sourceInfo.id,
        sourceName: sourceInfo.name,
        providerId: parts[0],
        title: MediaTitle(english: detail.title),
        cover: detail.cover,
        description: detail.description,
        genres: detail.genre,
      );
    } catch (e, st) {
      methodLog.e('getDetails failed', e, st);
      throw Exception('Failed to get details');
    }
  }
}
