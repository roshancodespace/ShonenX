import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/remote_config/models/remote_config.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class RemoteConfigService {
  static const String _configUrl =
      'https://raw.githubusercontent.com/roshancodespace/shonenx-config/refs/heads/main/remote_config.json';

  static const String _cacheKey = 'remote_config_cache';
  static const String _seenAnnouncementsKey = 'remote_config_seen_announcements';
  static const String _lastUpdateVersionSeenKey =
      'remote_config_last_update_version_seen';

  final SharedPreferences _prefs;
  final _log = AppLogger.scope('RemoteConfigService');

  RemoteConfig? _currentConfig;

  RemoteConfigService(this._prefs);

  RemoteConfig? get config => _currentConfig;

  Future<void> init() async {
    _log.i('Initializing remote config...');
    // Load from cache first
    final cachedData = _prefs.getString(_cacheKey);
    if (cachedData != null) {
      try {
        _currentConfig = RemoteConfig.fromJson(jsonDecode(cachedData));
        _log.s('Loaded config from cache');
      } catch (e) {
        _log.w('Failed to parse cached config', e);
      }
    }

    // Fetch fresh from network
    await fetchRemoteConfig();
  }

  Future<void> fetchRemoteConfig() async {
    try {
      final uri = Uri.parse(_configUrl).replace(
        queryParameters: {'_t': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final response = await http.get(
        uri,
        headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
      );
      if (response.statusCode == 200) {
        final jsonStr = response.body;

        // Try to parse it to ensure it's valid
        final parsedConfig = RemoteConfig.fromJson(jsonDecode(jsonStr));
        _currentConfig = parsedConfig;

        // Save valid json string to cache
        await _prefs.setString(_cacheKey, jsonStr);
        _log.s('Successfully fetched and cached remote config');
      } else {
        _log.w('Failed to fetch config. HTTP Status: ${response.statusCode}');
      }
    } catch (e) {
      _log.e('Error fetching remote config', e);
      // Fallback to _currentConfig which is already loaded from cache
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

  // Update logic
  bool shouldShowUpdate(String currentVersion) {
    if (_currentConfig == null) return false;
    
    final minVersion = _currentConfig!.minimumVersion;
    if (minVersion.isEmpty) return false;

    // Check if we already "downloaded" this specific tag
    final lastDownloaded = _prefs.getString(_lastUpdateVersionSeenKey);
    if (lastDownloaded == minVersion) return false;

    // Compare versions. If current < minVersion, force update.
    return _compareVersions(currentVersion, minVersion) < 0;
  }

  Future<void> markUpdateAsDownloaded(String versionTag) async {
    await _prefs.setString(_lastUpdateVersionSeenKey, versionTag);
  }

  /// Returns < 0 if v1 < v2, > 0 if v1 > v2, 0 if v1 == v2
  int _compareVersions(String v1, String v2) {
    final cleanV1 = v1.replaceAll('v', '').split('+').first;
    final cleanV2 = v2.replaceAll('v', '').split('+').first;
    
    final parts1 = cleanV1.split('-');
    final parts2 = cleanV2.split('-');

    final main1 = parts1[0].split('.');
    final main2 = parts2[0].split('.');

    for (var i = 0; i < 3; i++) {
      final numA = i < main1.length ? int.tryParse(main1[i]) ?? 0 : 0;
      final numB = i < main2.length ? int.tryParse(main2[i]) ?? 0 : 0;
      if (numA > numB) return 1;
      if (numA < numB) return -1;
    }
    
    // If main versions are equal, compare pre-release tags
    final pre1 = parts1.length > 1 ? parts1[1] : '';
    final pre2 = parts2.length > 1 ? parts2[1] : '';

    if (pre1.isEmpty && pre2.isNotEmpty) return 1; // 2.0.0 > 2.0.0-alpha
    if (pre1.isNotEmpty && pre2.isEmpty) return -1; // 2.0.0-alpha < 2.0.0
    
    return pre1.compareTo(pre2);
  }

  // Source Status Logic
  bool isSourceDisabled(String sourceId) {
    if (_currentConfig == null) return false;
    final sourceConfig = _currentConfig!.sources[sourceId];
    return sourceConfig?.disabled ?? false;
  }
}
