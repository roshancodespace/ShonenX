import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/core/models/settings/content_settings_model.dart';
import 'package:shonenx/core/models/settings/download_settings_model.dart';
import 'package:shonenx/core/models/settings/experimental_model.dart';
import 'package:shonenx/core/models/settings/player_model.dart';
import 'package:shonenx/core/models/settings/theme_model.dart';
import 'package:shonenx/core/models/settings/ui_model.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/shared/providers/permissions_provider.dart';
import 'package:shonenx/storage_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref);
});

class BackupService {
  final Ref _ref;

  BackupService(this._ref);

  static const String _progressBox = 'anime_watch_progress';

  Future<void> exportData({
    required bool includeWatchlist,
    required bool includeSettings,
  }) async {
    try {
      final Map<String, dynamic> dataPayload = {};

      if (includeWatchlist) {
        final progressBox = Hive.box<AnimeWatchProgressEntry>(_progressBox);
        dataPayload['watchlist'] = progressBox.toMap().map(
              (key, value) => MapEntry(key.toString(), value.toMap()),
            );
      }

      if (includeSettings) {
        final settingsData = <String, dynamic>{};

        void addSetting<T>(String key, String prefKey, Map<String, dynamic> Function(String) parser) {
          final jsonStr = sharedPrefs.getString(prefKey);
          if (jsonStr != null) {
            try {
              settingsData[key] = parser(jsonStr);
            } catch (_) {}
          }
        }

        addSetting('theme', 'theme_settings', (j) => ThemeModel.fromJson(j).toMap());
        addSetting('download', 'download_settings', (j) => DownloadSettingsModel.fromJson(j).toMap());
        addSetting('player', 'player_settings', (j) => PlayerModel.fromJson(j).toMap());
        addSetting('ui', 'ui_settings', (j) => UiSettings.fromJson(j).toMap());
        addSetting('experimental', 'experimental_settings', (j) => ExperimentalFeaturesModel.fromJson(j).toMap());
        addSetting('content', 'content_settings', (j) => ContentSettingsModel.fromJson(j).toMap());

        dataPayload['settings'] = settingsData;
      }

      final Map<String, dynamic> backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'data': dataPayload,
      };

      final jsonString = jsonEncode(backupData);
      final fileName = 'shonenx_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      if (Platform.isAndroid) {
        final hasPermission = await _ref.read(permissionsProvider.notifier).requestStoragePermission();
        
        if (hasPermission) {
          final dir = await StorageProvider.getDefaultDirectory();
          if (dir != null) {
            final file = File('${dir.path}/$fileName');
            await file.writeAsString(jsonString);
            AppLogger.i('Backup saved to ${file.path}');
            return;
          }
        }

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(jsonString);
        await Share.shareXFiles([XFile(file.path)], text: 'ShonenX Backup');
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsString(jsonString);
          AppLogger.i('Backup saved to ${file.path}');
        }
      }
    } catch (e, s) {
      AppLogger.e('Failed to export data', e, s);
      rethrow;
    }
  }

  Future<void> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      if (backupData['version'] != 1) {
        throw Exception('Unsupported backup version');
      }

      final data = backupData['data'] as Map<String, dynamic>? ?? {};

      if (data.containsKey('watchlist')) {
        final watchlistData = data['watchlist'] as Map<String, dynamic>;
        final box = Hive.box<AnimeWatchProgressEntry>(_progressBox);
        await box.clear();

        final Map<String, AnimeWatchProgressEntry> entries = {};
        for (var entry in watchlistData.entries) {
          try {
            entries[entry.key] = AnimeWatchProgressEntry.fromMap(
              Map<String, dynamic>.from(entry.value),
            );
          } catch (_) {}
        }
        await box.putAll(entries);
      }

      if (data.containsKey('settings')) {
        final settingsData = data['settings'] as Map<String, dynamic>;

        Future<void> restoreSetting(String key, String prefKey, dynamic Function(Map<String, dynamic>) parser) async {
          if (settingsData.containsKey(key)) {
            try {
              final model = parser(settingsData[key]);
              await sharedPrefs.setString(prefKey, model.toJson());
            } catch (_) {}
          }
        }

        await restoreSetting('theme', 'theme_settings', (m) => ThemeModel.fromMap(m));
        await restoreSetting('download', 'download_settings', (m) => DownloadSettingsModel.fromMap(m));
        await restoreSetting('player', 'player_settings', (m) => PlayerModel.fromMap(m));
        await restoreSetting('ui', 'ui_settings', (m) => UiSettings.fromMap(m));
        await restoreSetting('experimental', 'experimental_settings', (m) => ExperimentalFeaturesModel.fromMap(m));
        await restoreSetting('content', 'content_settings', (m) => ContentSettingsModel.fromMap(m));
      }
    } catch (e, s) {
      AppLogger.e('Failed to import data', e, s);
      rethrow;
    }
  }
}