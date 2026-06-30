import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/remote_config/models/remote_config.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class RemoteConfigService {
  static const String _configUrl =
      'https://raw.githubusercontent.com/roshancodespace/shonenx-config/refs/heads/main/remote_config.json';

  static const String _cacheKey = 'remote_config_cache';
  static const String _seenAnnouncementsKey =
      'remote_config_seen_announcements';

  final SharedPreferences _prefs;
  final _log = AppLogger.scope('RemoteConfigService');

  RemoteConfig? _currentConfig;

  RemoteConfigService(this._prefs);

  RemoteConfig? get config => _currentConfig;

  Future<void> init() async {
    _log.i('Initializing remote config...');
    final cachedData = _prefs.getString(_cacheKey);
    if (cachedData != null) {
      try {
        _currentConfig = RemoteConfig.fromJson(jsonDecode(cachedData));
        _log.s('Loaded config from cache');
      } catch (e) {
        _log.w('Failed to parse cached config', e);
      }
    }
    await fetchRemoteConfig();
  }

  Future<void> fetchRemoteConfig() async {
    try {
      final uri = Uri.parse(_configUrl).replace(
        queryParameters: {
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await http.get(
        uri,
        headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
      );
      if (response.statusCode == 200) {
        final jsonStr = response.body;
        final parsedConfig = RemoteConfig.fromJson(jsonDecode(jsonStr));
        _currentConfig = parsedConfig;
        await _prefs.setString(_cacheKey, jsonStr);
        _log.s('Successfully fetched and cached remote config');
      } else {
        _log.w('Failed to fetch config. HTTP Status: ${response.statusCode}');
      }
    } catch (e) {
      _log.e('Error fetching remote config', e);
    }
  }

  // Announcement logic
  Announcement? getActiveAppAnnouncement() {
    if (_currentConfig == null) return null;

    final appAnnouncements = _currentConfig!.announcements.app;
    final seenIds = _prefs.getStringList(_seenAnnouncementsKey) ?? [];

    for (final ann in appAnnouncements) {
      if (ann.enabled && !seenIds.contains(ann.id.toString())) {
        return ann;
      }
    }

    return null;
  }

  Future<void> markAnnouncementAsSeen(int id) async {
    final seenIds = _prefs.getStringList(_seenAnnouncementsKey) ?? [];
    if (!seenIds.contains(id.toString())) {
      seenIds.add(id.toString());
      await _prefs.setStringList(_seenAnnouncementsKey, seenIds);
    }
  }

  // Source Status Logic
  bool isSourceDisabled(String sourceId) {
    if (_currentConfig == null) return false;
    final sourceConfig = _currentConfig!.sources[sourceId];
    return sourceConfig?.disabled ?? false;
  }
}
