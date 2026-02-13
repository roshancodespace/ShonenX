import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/permissions.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/settings/model/content_settings_model.dart';
import 'package:shonenx/features/settings/model/download_settings_model.dart';
import 'package:shonenx/features/settings/model/experimental_model.dart';
import 'package:shonenx/features/settings/model/player_model.dart';
import 'package:shonenx/features/settings/model/theme_model.dart';
import 'package:shonenx/features/settings/model/ui_model.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/storage_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class BackupService {
  static const String _progressBox = 'anime_watch_progress';

  Future<void> exportData({
    required bool includeWatchlist,
    required bool includeSettings,
  }) async {
    try {
      final Map<String, dynamic> backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'data': {},
      };

      if (includeWatchlist) {
        final progressBox = Hive.box<AnimeWatchProgressEntry>(_progressBox);
        final progressData = progressBox.toMap().map(
          (key, value) => MapEntry(key.toString(), value.toMap()),
        );
        backupData['data']['watchlist'] = progressData;
      }

      if (includeSettings) {
        final settingsData = <String, dynamic>{};

        // Theme
        final themeJson = sharedPrefs.getString('theme_settings');
        if (themeJson != null) {
          settingsData['theme'] = ThemeModel.fromJson(themeJson).toMap();
        }

        // Download
        final downloadJson = sharedPrefs.getString('download_settings');
        if (downloadJson != null) {
          settingsData['download'] = DownloadSettingsModel.fromJson(
            downloadJson,
          ).toMap();
        }

        // Player
        final playerJson = sharedPrefs.getString('player_settings');
        if (playerJson != null) {
          settingsData['player'] = PlayerModel.fromJson(playerJson).toMap();
        }

        // UI
        final uiJson = sharedPrefs.getString('ui_settings');
        if (uiJson != null) {
          settingsData['ui'] = UiSettings.fromJson(uiJson).toMap();
        }

        // Experimental
        final experimentalJson = sharedPrefs.getString('experimental_settings');
        if (experimentalJson != null) {
          settingsData['experimental'] = ExperimentalFeaturesModel.fromJson(
            experimentalJson,
          ).toMap();
        }

        // Content
        final contentJson = sharedPrefs.getString('content_settings');
        if (contentJson != null) {
          settingsData['content'] = ContentSettingsModel.fromJson(
            contentJson,
          ).toMap();
        }

        backupData['data']['settings'] = settingsData;
      }

      final jsonString = jsonEncode(backupData);
      final fileName =
          'shonenx_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      if (Platform.isAndroid) {
        if (await Permissions.requestStoragePermission()) {
          final dir = await StorageProvider.getDefaultDirectory();
          if (dir != null) {
            final file = File('${dir.path}/$fileName');
            await file.writeAsString(jsonString);
            AppLogger.i('Backup saved to ${file.path}');
            return;
          }
        }
        // Fallback to share if permission denied or directory not found
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(jsonString);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'ShonenX Backup'),
        );
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

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> backupData = jsonDecode(jsonString);

        if (backupData['version'] != 1) {
          throw Exception('Unsupported backup version');
        }

        final data = backupData['data'] as Map<String, dynamic>;

        if (data.containsKey('watchlist')) {
          final watchlistData = data['watchlist'] as Map<String, dynamic>;
          final box = Hive.box<AnimeWatchProgressEntry>(_progressBox);
          await box.clear();

          final Map<String, AnimeWatchProgressEntry> entries = {};
          for (var entry in watchlistData.entries) {
            entries[entry.key] = AnimeWatchProgressEntry.fromMap(
              Map<String, dynamic>.from(entry.value),
            );
          }
          await box.putAll(entries);
        }

        if (data.containsKey('settings')) {
          final settingsData = data['settings'] as Map<String, dynamic>;

          if (settingsData.containsKey('theme')) {
            final model = ThemeModel.fromMap(settingsData['theme']);
            await sharedPrefs.setString('theme_settings', model.toJson());
          }
          if (settingsData.containsKey('download')) {
            final model = DownloadSettingsModel.fromMap(
              settingsData['download'],
            );
            await sharedPrefs.setString('download_settings', model.toJson());
          }
          if (settingsData.containsKey('player')) {
            final model = PlayerModel.fromMap(settingsData['player']);
            await sharedPrefs.setString('player_settings', model.toJson());
          }
          if (settingsData.containsKey('ui')) {
            final model = UiSettings.fromMap(settingsData['ui']);
            await sharedPrefs.setString('ui_settings', model.toJson());
          }
          if (settingsData.containsKey('experimental')) {
            final model = ExperimentalFeaturesModel.fromMap(
              settingsData['experimental'],
            );
            await sharedPrefs.setString(
              'experimental_settings',
              model.toJson(),
            );
          }
          if (settingsData.containsKey('content')) {
            final model = ContentSettingsModel.fromMap(settingsData['content']);
            await sharedPrefs.setString('content_settings', model.toJson());
          }
        }
      }
    } catch (e, s) {
      AppLogger.e('Failed to import data', e, s);
      rethrow;
    }
  }
}
