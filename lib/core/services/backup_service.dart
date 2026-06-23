import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';

enum BackupCategory {
  library('Library', 'Saved anime with status & progress'),
  watchHistory('Watch History', 'Episode watch positions'),
  trackerLinks('Tracker Links', 'AniList / MAL mappings'),
  appPreferences('App Preferences', 'Theme, player, UI & other settings');

  final String label;
  final String description;
  const BackupCategory(this.label, this.description);

  IconData get icon => switch (this) {
    library => Icons.collections_bookmark_outlined,
    watchHistory => Icons.history_outlined,
    trackerLinks => Icons.link_outlined,
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
    final map = jsonDecode(source) as Map<String, dynamic>;
    return BackupManifest(
      appVersion: map['appVersion'] as String? ?? 'unknown',
      exportDate:
          DateTime.tryParse(map['exportDate'] as String? ?? '') ??
          DateTime.now(),
      categories: (map['categories'] as List<dynamic>? ?? [])
          .map(
            (name) => BackupCategory.values.firstWhere(
              (c) => c.name == name,
              orElse: () => BackupCategory.library,
            ),
          )
          .toSet(),
      data: map['data'] as Map<String, dynamic>? ?? {},
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
        case BackupCategory.watchHistory:
          data['watchHistory'] = await _exportWatchHistory();
        case BackupCategory.trackerLinks:
          data['trackerLinks'] = await _exportTrackerLinks();
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
        case BackupCategory.watchHistory:
          await _importWatchHistory(
            manifest.data['watchHistory'] as List<dynamic>?,
          );
        case BackupCategory.trackerLinks:
          await _importTrackerLinks(
            manifest.data['trackerLinks'] as List<dynamic>?,
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
      BackupCategory.watchHistory: await _isar.watchHistoryEntrys.count(),
      BackupCategory.trackerLinks: await _isar.isarTrackerLinks.count(),
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

  Future<List<Map<String, dynamic>>> _exportWatchHistory() async {
    final entries = await _isar.watchHistoryEntrys.where().findAll();
    return entries.map((e) => e.toBackupMap()).toList();
  }

  Future<List<Map<String, dynamic>>> _exportTrackerLinks() async {
    final entries = await _isar.isarTrackerLinks.where().findAll();
    return entries.map((e) => e.toBackupMap()).toList();
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
        await _isar.libraryEntrys.put(
          LibraryEntry.fromBackupMap(item as Map<String, dynamic>),
        );
      }
    });
  }

  Future<void> _importWatchHistory(List<dynamic>? items) async {
    if (items == null || items.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.watchHistoryEntrys.clear();
      for (final item in items) {
        await _isar.watchHistoryEntrys.put(
          WatchHistoryEntry.fromBackupMap(item as Map<String, dynamic>),
        );
      }
    });
  }

  Future<void> _importTrackerLinks(List<dynamic>? items) async {
    if (items == null || items.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.isarTrackerLinks.clear();
      for (final item in items) {
        await _isar.isarTrackerLinks.put(
          IsarTrackerLink.fromBackupMap(item as Map<String, dynamic>),
        );
      }
    });
  }

  Future<void> _importPreferences(Map<String, dynamic>? prefs) async {
    if (prefs == null || prefs.isEmpty) return;
    for (final e in prefs.entries) {
      final value = e.value;
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
      }
    }
  }
}
