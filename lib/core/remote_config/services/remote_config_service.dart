import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/remote_config/models/remote_config.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class RemoteConfigService {
  static const String _configUrl =
      'https://raw.githubusercontent.com/roshancodespace/shonenx-config/refs/heads/main/remote_config.json';

  static const String _cacheKey = 'remote_config_cache';
  static const String _channelKey = 'remote_config_channel';
  static const String _seenAnnouncementKey = 'remote_config_seen_announcement';
  static const String _lastUpdateIdSeenKey =
      'remote_config_last_update_id_seen';

  final SharedPreferences _prefs;
  final _log = AppLogger.scope('RemoteConfigService');

  RemoteConfig? _currentConfig;

  RemoteConfigService(this._prefs);

  RemoteConfig? get config => _currentConfig;

  ReleaseChannel get currentChannel {
    final str = _prefs.getString(_channelKey) ?? 'stable';
    return str == 'test' ? ReleaseChannel.test : ReleaseChannel.stable;
  }

  Future<void> setChannel(ReleaseChannel channel) async {
    await _prefs.setString(_channelKey, channel.name);
  }

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
      final response = await http.get(Uri.parse(_configUrl));
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
  bool shouldShowAnnouncement() {
    if (_currentConfig?.announcement == null) return false;
    final announcementId = _currentConfig!.announcement!.id;
    final seenId = _prefs.getString(_seenAnnouncementKey);
    return announcementId != seenId;
  }

  Future<void> markAnnouncementAsSeen() async {
    if (_currentConfig?.announcement != null) {
      await _prefs.setString(
        _seenAnnouncementKey,
        _currentConfig!.announcement!.id,
      );
    }
  }

  // Update logic
  bool shouldShowUpdate(int currentAppUpdateId) {
    final channelConfig = _currentConfig?.getChannelConfig(currentChannel);
    if (channelConfig == null) return false;

    final remoteUpdateId = channelConfig.updateId;

    if (remoteUpdateId > currentAppUpdateId) {
      // If force update, we ALWAYS show it regardless of 'seen'
      if (channelConfig.forceUpdate) return true;

      // Otherwise, only show if we haven't seen it yet
      final lastSeenUpdateId = _prefs.getInt(_lastUpdateIdSeenKey) ?? 0;
      return remoteUpdateId > lastSeenUpdateId;
    }
    return false;
  }

  Future<void> markUpdateAsSeen() async {
    final channelConfig = _currentConfig?.getChannelConfig(currentChannel);
    if (channelConfig != null) {
      await _prefs.setInt(_lastUpdateIdSeenKey, channelConfig.updateId);
    }
  }

  // Source Status Logic
  bool isSourceDisabled(String sourceId) {
    if (_currentConfig == null) return false;
    final sourceConfig = _currentConfig!.sources[sourceId];
    return sourceConfig?.disabled ?? false;
  }
}
