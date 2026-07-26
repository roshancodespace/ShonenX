import 'dart:async';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/source_engine/providers/media_source.dart';
import 'package:shonenx/source_engine/utils/parsers.dart';

class _CacheEntry<T> {
  final T data;
  final Timer timer;
  _CacheEntry(this.data, this.timer);
}

class _SourceCache {
  final Map<String, _CacheEntry> _store = {};

  void set<T>(String key, T value) {
    _store[key]?.timer.cancel();
    final timer = Timer(const Duration(minutes: 5), () {
      _store.remove(key);
    });
    _store[key] = _CacheEntry(value, timer);
  }

  T? get<T>(String key) {
    return _store[key]?.data as T?;
  }

  void clear() {
    for (final entry in _store.values) {
      entry.timer.cancel();
    }
    _store.clear();
  }
}

abstract class BaseSourceAdapter implements MediaSource {
  @override
  final SourceInfo sourceInfo;
  final bridge.Source source;
  final _SourceCache _cache = _SourceCache();

  BaseSourceAdapter({required this.sourceInfo, required this.source});

  ScopedLogger get log;

  MediaType get mediaType => sourceInfo.mediaType;

  final Map<String, bridge.SourcePreference> _preferencesCache = {};

  @override
  Future<List<SourceSetting>> getSettingsSchema() async {
    final cacheKey = 'getSettingsSchema';
    final cached = _cache.get<List<SourceSetting>>(cacheKey);
    if (cached != null) return cached;

    final methodLog = log.child('getSettingsSchema');
    try {
      final schema = await source.methods.getPreference();
      _preferencesCache.clear();
      final List<SourceSetting> settings = [];

      for (final pref in schema) {
        if (pref.key == null || pref.type == null) continue;
        _preferencesCache[pref.key!] = pref;

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

      if (settings.isNotEmpty) {
        _cache.set(cacheKey, settings);
      }
      return settings;
    } catch (e, st) {
      methodLog.e('Failed to fetch settings schema', e, st);
      return [];
    }
  }

  Future<bool> saveSetting(String settingId, dynamic value) async {
    final methodLog = log.child('saveSetting');
    try {
      bridge.SourcePreference? pref = _preferencesCache[settingId];
      if (pref == null) {
        final schema = await source.methods.getPreference();
        for (final p in schema) {
          if (p.key != null) {
            _preferencesCache[p.key!] = p;
          }
        }
        pref = _preferencesCache[settingId];
      }

      final targetPref = pref ?? bridge.SourcePreference(key: settingId);

      if (targetPref.type == 'checkbox' ||
          targetPref.checkBoxPreference != null) {
        targetPref.checkBoxPreference?.value = value is bool
            ? value
            : (value.toString().toLowerCase() == 'true');
      } else if (targetPref.type == 'switch' ||
          targetPref.switchPreferenceCompat != null) {
        targetPref.switchPreferenceCompat?.value = value is bool
            ? value
            : (value.toString().toLowerCase() == 'true');
      } else if (targetPref.type == 'list' ||
          targetPref.listPreference != null) {
        targetPref.listPreference?.value = value?.toString();
        final entryValues = targetPref.listPreference?.entryValues;
        if (entryValues != null) {
          final idx = entryValues.indexOf(value?.toString() ?? '');
          if (idx != -1) targetPref.listPreference?.valueIndex = idx;
        }
      } else if (targetPref.type == 'multi_select' ||
          targetPref.multiSelectListPreference != null) {
        final list = value is List
            ? value.map((e) => e.toString()).toList()
            : <String>[];
        targetPref.multiSelectListPreference?.values = list;
      } else if (targetPref.type == 'text' ||
          targetPref.editTextPreference != null) {
        targetPref.editTextPreference?.value = value?.toString();
      }

      methodLog.i('Saving setting $settingId to source ${sourceInfo.id}');
      final success = await source.methods.setPreference(targetPref, value);
      if (success) {
        _cache.clear();
      }
      return success;
    } catch (e, st) {
      methodLog.e('Failed to save setting $settingId', e, st);
      return false;
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
    final cacheKey =
        'search|$query|$type|$page|$isAdult|${sort.join(',')}|${genres.join(',')}|${tags.join(',')}';
    final cached = _cache.get<List<UnifiedMedia>>(cacheKey);
    if (cached != null) return cached;

    final methodLog = log.child('search');
    try {
      methodLog.i('query=$query page=$page genres=$genres tags=$tags');
      final results = await source.methods.search(query, page, [
        ...genres,
        ...tags,
      ]);
      methodLog.d('results=${results.list.length}');

      final parsed = results.list
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

      if (parsed.isNotEmpty) {
        _cache.set(cacheKey, parsed);
      }
      return parsed;
    } catch (e, st) {
      methodLog.e('search failed', e, st);
      return [];
    }
  }

  @override
  Future<List<UnifiedMedia>> getTrending({int page = 1}) async {
    final cacheKey = 'getTrending|$page';
    final cached = _cache.get<List<UnifiedMedia>>(cacheKey);
    if (cached != null) return cached;

    final methodLog = log.child('getTrending');
    try {
      methodLog.i('page=$page');
      bridge.Pages results = await source.methods.getPopular(page);
      if (results.list.isEmpty) {
        results = await source.methods.getLatestUpdates(page);
      }
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

      if (list.isNotEmpty) {
        _cache.set(cacheKey, list);
        return list;
      }
      methodLog.i('getTrending returned empty, falling back to search("")');
      final fallback = await search('', mediaType, page: page);
      if (fallback.isNotEmpty) {
        _cache.set(cacheKey, fallback);
      }
      return fallback;
    } catch (e, st) {
      methodLog.e('getTrending failed, falling back to search("")', e, st);
      try {
        final fallback = await search('', mediaType, page: page);
        if (fallback.isNotEmpty) {
          _cache.set(cacheKey, fallback);
        }
        return fallback;
      } catch (_) {
        return [];
      }
    }
  }

  Future<bridge.DMedia> getRawDetail(String providerId) async {
    final cacheKey = 'getRawDetail|$providerId';
    final cached = _cache.get<bridge.DMedia>(cacheKey);
    if (cached != null) return cached;

    final parts = providerId.split('|');
    final detail = await source.methods.getDetail(
      bridge.DMedia(url: parts[0], title: parts.length > 1 ? parts[1] : ''),
    );
    _cache.set(cacheKey, detail);
    return detail;
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) async {
    final cacheKey = 'getDetails|$providerId|$type';
    final cached = _cache.get<UnifiedMedia>(cacheKey);
    if (cached != null) return cached;

    final methodLog = log.child('getDetails');
    try {
      final detail = await getRawDetail(providerId);

      final extraInfo = detail.toMediaInfo();

      final parts = providerId.split('|');
      final parsed = UnifiedMedia(
        id: providerId,
        type: mediaType,
        idMal: extraInfo?.malId?.toString(),
        sourceId: sourceInfo.id,
        sourceName: sourceInfo.name,
        providerId: parts[0],
        title: MediaTitle(english: detail.title),
        cover: detail.cover,
        description: detail.description,
        genres: detail.genre,
      );
      _cache.set(cacheKey, parsed);
      return parsed;
    } catch (e, st) {
      methodLog.e('getDetails failed', e, st);
      throw Exception('Failed to get details');
    }
  }
}
