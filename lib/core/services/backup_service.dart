import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/services/notification_service.dart';
import 'package:shonenx/features/discovery/domain/media_preference.dart';
import 'package:shonenx/features/history/domain/models/history_entry.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/notifications/domain/models/notification_subscription.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';

enum BackupCategory {
  library('Library', 'Saved anime & manga with status & progress'),
  history('History', 'Watch & read history positions & progress'),
  notifications(
    'Notification Subscriptions',
    'Airing alerts & chapter alert subscriptions',
  ),
  trackerLinks('Tracker Links', 'AniList / MAL mappings'),
  mediaPreferences(
    'Source Preferences',
    'Preferred sources & manual match overrides',
  ),
  appPreferences('App Preferences', 'Theme, player, UI & other settings');

  final String label;
  final String description;
  const BackupCategory(this.label, this.description);

  IconData get icon => switch (this) {
    library => Icons.collections_bookmark_outlined,
    history => Icons.history_outlined,
    notifications => Icons.notifications_active_outlined,
    trackerLinks => Icons.link_outlined,
    mediaPreferences => Icons.swap_horiz_outlined,
    appPreferences => Icons.tune_outlined,
  };
}

class BackupManifest {
  final String appVersion;
  final DateTime exportDate;
  final Set<BackupCategory> categories;
  final Map<String, dynamic> data;

  const BackupManifest({
    required this.appVersion,
    required this.exportDate,
    required this.categories,
    required this.data,
  });

  int countFor(BackupCategory category) {
    final value = data[category.name];
    if (value is List) return value.length;
    if (value is Map) return value.length;

    // Fallbacks for legacy/alternative keys
    if (category == BackupCategory.history) {
      int count = 0;
      final wh = data['watchHistory'];
      if (wh is List) count += wh.length;
      final rh = data['readHistory'];
      if (rh is List) count += rh.length;
      if (count > 0) return count;
    } else if (category == BackupCategory.library) {
      final wl = data['watchlist'];
      if (wl is Map) return wl.length;
      final al = data['animeLibrary'];
      final ml = data['mangaLibrary'];
      int count = 0;
      if (al is List) count += al.length;
      if (ml is List) count += ml.length;
      if (count > 0) return count;
    } else if (category == BackupCategory.appPreferences) {
      final s = data['settings'];
      if (s is Map) return s.length;
      if (s is List) return s.length;
    }
    return 0;
  }

  String toJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'appVersion': appVersion,
      'exportDate': exportDate.toIso8601String(),
      'categories': categories.map((c) => c.name).toList(),
      'data': data,
    });
  }

  factory BackupManifest.fromJson(String source) {
    String cleaned = source.trim();
    if (cleaned.startsWith('\uFEFF')) {
      cleaned = cleaned.substring(1).trim();
    }
    // Remove markdown code fences if wrapped in them
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();
    }

    Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map) {
        map = Map<String, dynamic>.from(decoded);
      } else {
        throw const FormatException('Root backup JSON is not an object');
      }
    } catch (_) {
      // Fallback repair: strip trailing commas before closing braces/brackets
      final repaired = cleaned.replaceAllMapped(
        RegExp(r',\s*([}\]])'),
        (match) => match.group(1)!,
      );
      final decoded = jsonDecode(repaired);
      if (decoded is Map) {
        map = Map<String, dynamic>.from(decoded);
      } else {
        throw const FormatException('Root backup JSON is not an object');
      }
    }

    // 1. Resolve 'data' payload (handling double-encoded strings or root-level maps)
    dynamic rawData = map['data'];
    if (rawData is String) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {}
    }

    final data = <String, dynamic>{};
    if (rawData is Map) {
      for (final e in rawData.entries) {
        data[e.key.toString()] = e.value;
      }
    } else {
      // Extract root-level data keys if 'data' object is missing
      for (final key in [
        'library',
        'history',
        'watchHistory',
        'readHistory',
        'notifications',
        'trackerLinks',
        'mediaPreferences',
        'appPreferences',
        'watchlist',
        'animeLibrary',
        'mangaLibrary',
        'novelLibrary',
        'settings',
      ]) {
        if (map.containsKey(key)) {
          data[key] = map[key];
        }
      }
    }

    // 2. Normalize legacy library formats (Hive watchlist / AnymeX libraries)
    if (data['watchlist'] is Map && data['library'] == null) {
      final list = <Map<String, dynamic>>[];
      for (final val in (data['watchlist'] as Map).values) {
        if (val is Map) list.add(Map<String, dynamic>.from(val));
      }
      data['library'] = list;
    }
    if ((data['animeLibrary'] is List || data['mangaLibrary'] is List) &&
        data['library'] == null) {
      final anymexLib = <Map<String, dynamic>>[];
      if (data['animeLibrary'] is List) {
        for (final item in data['animeLibrary'] as List) {
          if (item is Map) anymexLib.add(Map<String, dynamic>.from(item));
        }
      }
      if (data['mangaLibrary'] is List) {
        for (final item in data['mangaLibrary'] as List) {
          if (item is Map) anymexLib.add(Map<String, dynamic>.from(item));
        }
      }
      if (anymexLib.isNotEmpty) {
        data['library'] = anymexLib;
      }
    }

    // 3. Normalize legacy settings formats
    if (data['settings'] != null && data['appPreferences'] == null) {
      if (data['settings'] is Map) {
        data['appPreferences'] = Map<String, dynamic>.from(
          data['settings'] as Map,
        );
      } else if (data['settings'] is List) {
        final prefMap = <String, dynamic>{};
        for (final item in data['settings'] as List) {
          if (item is Map && item['key'] != null) {
            prefMap[item['key'].toString()] = item['value'];
          }
        }
        data['appPreferences'] = prefMap;
      }
    }

    // 4. Normalize legacy watchHistory and readHistory into history
    if (data['history'] == null) {
      final combinedHistory = <dynamic>[];
      if (data['watchHistory'] is List) {
        combinedHistory.addAll(data['watchHistory'] as List);
      }
      if (data['readHistory'] is List) {
        combinedHistory.addAll(data['readHistory'] as List);
      }
      if (combinedHistory.isNotEmpty) {
        data['history'] = combinedHistory;
      }
    }

    // 5. Parse and auto-detect categories
    final categories = <BackupCategory>{};
    final rawCats = map['categories'];
    if (rawCats is List) {
      for (final name in rawCats) {
        final str = name?.toString();
        if (str == 'watchHistory' || str == 'readHistory' || str == 'history') {
          categories.add(BackupCategory.history);
        } else if (str == 'library' ||
            str == 'watchlist' ||
            str == 'animeLibrary') {
          categories.add(BackupCategory.library);
        } else if (str == 'appPreferences' || str == 'settings') {
          categories.add(BackupCategory.appPreferences);
        } else {
          final matched = BackupCategory.values.where((c) => c.name == str);
          if (matched.isNotEmpty) {
            categories.add(matched.first);
          }
        }
      }
    }

    // Auto-detect categories from present data to recover broken manifests
    if (data.containsKey('library') ||
        data.containsKey('watchlist') ||
        data.containsKey('animeLibrary')) {
      categories.add(BackupCategory.library);
    }
    if (data.containsKey('history') ||
        data.containsKey('watchHistory') ||
        data.containsKey('readHistory')) {
      categories.add(BackupCategory.history);
    }
    if (data.containsKey('notifications')) {
      categories.add(BackupCategory.notifications);
    }
    if (data.containsKey('trackerLinks')) {
      categories.add(BackupCategory.trackerLinks);
    }
    if (data.containsKey('mediaPreferences')) {
      categories.add(BackupCategory.mediaPreferences);
    }
    if (data.containsKey('appPreferences') || data.containsKey('settings')) {
      categories.add(BackupCategory.appPreferences);
    }

    // Fallback date and version
    final exportDateStr = (map['exportDate'] ?? map['timestamp'] ?? map['date'])
        ?.toString();
    final exportDate = DateTime.tryParse(exportDateStr ?? '') ?? DateTime.now();
    final appVersion =
        (map['appVersion'] ?? map['version'])?.toString() ?? 'unknown';

    return BackupManifest(
      appVersion: appVersion,
      exportDate: exportDate,
      categories: categories,
      data: data,
    );
  }
}

class BackupService {
  final Isar _isar;
  final SharedPreferences _prefs;

  static const _appVersion = '2.0.0';

  static const _prefKeys = [
    'app_theme_data',
    'ui_preferences',
    'player_prefs',
    'download_prefs',
    'discovery_mode',
    'discovery_active_sources',
    'home_layout_data',
    'app_tracking_prefs',
    'media_kit_prefs',
    'tracker_profiles_data',
    'currentManager',
    'cache_config',
  ];

  BackupService(this._isar, this._prefs);

  Future<BackupManifest> exportData(Set<BackupCategory> categories) async {
    final data = <String, dynamic>{};

    for (final cat in categories) {
      switch (cat) {
        case BackupCategory.library:
          data['library'] = await _exportLibrary();
        case BackupCategory.history:
          data['history'] = await _exportHistory();
        case BackupCategory.notifications:
          data['notifications'] = await _exportNotifications();
        case BackupCategory.trackerLinks:
          data['trackerLinks'] = await _exportTrackerLinks();
        case BackupCategory.mediaPreferences:
          data['mediaPreferences'] = await _exportMediaPreferences();
        case BackupCategory.appPreferences:
          data['appPreferences'] = _exportPreferences();
      }
    }

    return BackupManifest(
      appVersion: _appVersion,
      exportDate: DateTime.now(),
      categories: categories,
      data: data,
    );
  }

  Future<void> importData(
    BackupManifest manifest,
    Set<BackupCategory> categories,
  ) async {
    for (final cat in categories) {
      if (!manifest.categories.contains(cat)) continue;
      switch (cat) {
        case BackupCategory.library:
          await _importLibrary(manifest.data['library'] as List<dynamic>?);
        case BackupCategory.history:
          await _importHistory(manifest.data['history'] as List<dynamic>?);
          // If legacy separate keys are present and weren't in history
          if (manifest.data['history'] == null) {
            await _importLegacyHistory(
              watchHistory: manifest.data['watchHistory'] as List<dynamic>?,
              readHistory: manifest.data['readHistory'] as List<dynamic>?,
            );
          }
        case BackupCategory.notifications:
          await _importNotifications(
            manifest.data['notifications'] as List<dynamic>?,
          );
        case BackupCategory.trackerLinks:
          await _importTrackerLinks(
            manifest.data['trackerLinks'] as List<dynamic>?,
          );
        case BackupCategory.mediaPreferences:
          await _importMediaPreferences(
            manifest.data['mediaPreferences'] as List<dynamic>?,
          );
        case BackupCategory.appPreferences:
          await _importPreferences(
            manifest.data['appPreferences'] as Map<String, dynamic>?,
          );
      }
    }
  }

  Future<Map<BackupCategory, int>> getExistingCounts() async {
    return {
      BackupCategory.library: await _isar.libraryEntrys.count(),
      BackupCategory.history: await _isar.historyEntrys.count(),
      BackupCategory.notifications: await _isar.notificationSubscriptions
          .count(),
      BackupCategory.trackerLinks: await _isar.isarTrackerLinks.count(),
      BackupCategory.mediaPreferences: await _isar.mediaPreferences.count(),
      BackupCategory.appPreferences: _prefKeys
          .where((k) => _prefs.containsKey(k))
          .length,
    };
  }

  // Export helpers

  Future<List<Map<String, dynamic>>> _exportLibrary() async {
    final entries = await _isar.libraryEntrys.where().findAll();
    return entries.map((e) => e.toBackupMap()).toList();
  }

  Future<List<Map<String, dynamic>>> _exportHistory() async {
    final entries = await _isar.historyEntrys.where().findAll();
    return entries.map((e) => e.toBackupMap()).toList();
  }

  Future<List<Map<String, dynamic>>> _exportNotifications() async {
    final entries = await _isar.notificationSubscriptions.where().findAll();
    return entries.map((e) => e.toBackupMap()).toList();
  }

  Future<List<Map<String, dynamic>>> _exportTrackerLinks() async {
    final entries = await _isar.isarTrackerLinks.where().findAll();
    return entries.map((e) => e.toBackupMap()).toList();
  }

  Future<List<Map<String, dynamic>>> _exportMediaPreferences() async {
    final entries = await _isar.mediaPreferences.where().findAll();
    return entries
        .map(
          (e) => {
            'mediaTitle': e.mediaTitle,
            'preferredSourceId': e.preferredSourceId,
            'preferredSourceName': e.preferredSourceName,
            'preferredSourceType': e.preferredSourceType,
            'matchedMediaTitle': e.matchedMediaTitle ?? e.manualOverrideTitle,
            'matchedMediaId': e.matchedMediaId ?? e.manualOverrideId,
            'preferredTracker': e.preferredTracker ?? e.preferredAiringTracker,
            'trackerMediaId': e.trackerMediaId ?? e.manualAiringTrackerId,
            // Legacy keys mirrored for backward compatibility
            'manualOverrideTitle': e.matchedMediaTitle ?? e.manualOverrideTitle,
            'manualOverrideId': e.matchedMediaId ?? e.manualOverrideId,
            'preferredAiringTracker':
                e.preferredTracker ?? e.preferredAiringTracker,
            'manualAiringTrackerId':
                e.trackerMediaId ?? e.manualAiringTrackerId,
          },
        )
        .toList();
  }

  Map<String, dynamic> _exportPreferences() {
    final map = <String, dynamic>{};
    for (final key in _prefKeys) {
      final value = _prefs.get(key);
      if (value != null) map[key] = value;
    }
    return map;
  }

  Future<void> _importLibrary(List<dynamic>? items) async {
    if (items == null || items.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.libraryEntrys.clear();
      for (final item in items) {
        if (item is! Map) continue;
        try {
          final entry = LibraryEntry.fromBackupMap(
            Map<String, dynamic>.from(item),
          );
          if (entry.providerId.isEmpty && entry.title.isEmpty) continue;
          await _isar.libraryEntrys.put(entry);
        } catch (_) {}
      }
    });
  }

  Future<void> _importHistory(List<dynamic>? items) async {
    if (items == null || items.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.historyEntrys.clear();
      for (final item in items) {
        if (item is! Map) continue;
        try {
          final entry = HistoryEntry.fromBackupMap(
            Map<String, dynamic>.from(item),
          );
          if (entry.mediaId.isEmpty && entry.mediaTitle.isEmpty) continue;
          await _isar.historyEntrys.put(entry);
        } catch (_) {}
      }
    });
  }

  Future<void> _importLegacyHistory({
    List<dynamic>? watchHistory,
    List<dynamic>? readHistory,
  }) async {
    final items = <dynamic>[
      if (watchHistory != null) ...watchHistory,
      if (readHistory != null) ...readHistory,
    ];
    if (items.isEmpty) return;
    await _importHistory(items);
  }

  Future<void> _importNotifications(List<dynamic>? items) async {
    if (items == null || items.isEmpty) return;
    final notifService = NotificationService.instance;
    await _isar.writeTxn(() async {
      await _isar.notificationSubscriptions.clear();
      for (final item in items) {
        if (item is! Map) continue;
        try {
          final sub = NotificationSubscription.fromBackupMap(
            Map<String, dynamic>.from(item),
          );
          if (sub.referenceId.isEmpty) continue;
          await _isar.notificationSubscriptions.put(sub);
        } catch (_) {}
      }
    });

    // Automatically reschedule all upcoming local notification reminders
    try {
      final activeSubs = await _isar.notificationSubscriptions
          .where()
          .findAll();
      for (final sub in activeSubs) {
        if (!sub.isEnabled) continue;
        if (sub.upcomingTime != null) {
          final scheduledTime = sub.upcomingTime!.subtract(
            Duration(minutes: sub.offsetMinutes),
          );
          if (scheduledTime.isAfter(DateTime.now())) {
            final notifId = NotificationService.generateId(
              sub.type.name,
              sub.referenceId,
              sub.upcomingIdentifier ?? 'unknown',
            );
            await notifService.schedule(
              id: notifId,
              title: 'New Update Alert: ${sub.title}',
              body:
                  'A new update (${sub.upcomingIdentifier ?? ''}) is arriving soon!',
              scheduleTime: scheduledTime,
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _importTrackerLinks(List<dynamic>? items) async {
    if (items == null || items.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.isarTrackerLinks.clear();
      for (final item in items) {
        if (item is! Map) continue;
        try {
          final link = IsarTrackerLink.fromBackupMap(
            Map<String, dynamic>.from(item),
          );
          if (link.primaryMediaId.isEmpty) continue;
          await _isar.isarTrackerLinks.put(link);
        } catch (_) {}
      }
    });
  }

  Future<void> _importMediaPreferences(List<dynamic>? items) async {
    if (items == null || items.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.mediaPreferences.clear();
      for (final item in items) {
        if (item is! Map) continue;
        try {
          final m = Map<String, dynamic>.from(item);
          final title = (m['mediaTitle'] ?? m['title'])?.toString();
          if (title == null || title.isEmpty) continue;

          final pref = MediaPreference()
            ..mediaTitle = title
            ..preferredSourceId =
                (m['preferredSourceId'] ?? m['sourceId'] ?? '')?.toString() ??
                ''
            ..preferredSourceName =
                (m['preferredSourceName'] ?? m['sourceName'] ?? '')
                    ?.toString() ??
                ''
            ..preferredSourceType =
                (m['preferredSourceType'] ?? m['sourceType'] ?? '')
                    ?.toString() ??
                ''
            ..matchedMediaTitle =
                (m['matchedMediaTitle'] ?? m['manualOverrideTitle'])?.toString()
            ..matchedMediaId = (m['matchedMediaId'] ?? m['manualOverrideId'])
                ?.toString()
            ..preferredTracker =
                (m['preferredTracker'] ?? m['preferredAiringTracker'])
                    ?.toString()
            ..trackerMediaId =
                (m['trackerMediaId'] ?? m['manualAiringTrackerId'])?.toString();
          await _isar.mediaPreferences.put(pref);
        } catch (_) {}
      }
    });
  }

  Future<void> _importPreferences(Map<String, dynamic>? prefs) async {
    if (prefs == null || prefs.isEmpty) return;
    for (final e in prefs.entries) {
      final value = e.value;
      try {
        if (value is String) {
          await _prefs.setString(e.key, value);
        } else if (value is int) {
          await _prefs.setInt(e.key, value);
        } else if (value is double) {
          await _prefs.setDouble(e.key, value);
        } else if (value is bool) {
          await _prefs.setBool(e.key, value);
        } else if (value is List) {
          await _prefs.setStringList(
            e.key,
            value.map((v) => v.toString()).toList(),
          );
        } else if (value is Map) {
          await _prefs.setString(e.key, jsonEncode(value));
        }
      } catch (_) {}
    }
  }
}
