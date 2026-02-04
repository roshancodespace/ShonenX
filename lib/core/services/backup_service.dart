import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/settings/model/content_settings_model.dart';
import 'package:shonenx/features/settings/model/download_settings_model.dart';
import 'package:shonenx/features/settings/model/experimental_model.dart';
import 'package:shonenx/features/settings/model/player_model.dart';
import 'package:shonenx/features/settings/model/theme_model.dart';
import 'package:shonenx/features/settings/model/ui_model.dart';
import 'package:shonenx/storage_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class BackupService {
  static const String _progressBox = 'anime_watch_progress';
  static const String _themeBox = 'theme_settings';
  static const String _downloadBox = 'download_settings';
  static const String _playerBox = 'player_settings';
  static const String _uiBox = 'ui_settings';
  static const String _experimentalBox = 'experimental_settings';
  static const String _contentBox = 'content_settings';

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

        if (Hive.isBoxOpen(_themeBox)) {
          final settings = Hive.box<ThemeModel>(_themeBox).get('settings');
          if (settings != null) settingsData['theme'] = settings.toMap();
        }
        if (Hive.isBoxOpen(_downloadBox)) {
          final settings = Hive.box<DownloadSettingsModel>(
            _downloadBox,
          ).get('settings');
          if (settings != null) settingsData['download'] = settings.toMap();
        }
        if (Hive.isBoxOpen(_playerBox)) {
          final settings = Hive.box<PlayerModel>(_playerBox).get('settings');
          if (settings != null) settingsData['player'] = settings.toMap();
        }
        // if (Hive.isBoxOpen(_uiBox)) {
        //   final settings = Hive.box<UiModel>(_uiBox).get('settings');
        //   if (settings != null) settingsData['ui'] = settings.toMap();
        // }
        if (Hive.isBoxOpen(_experimentalBox)) {
          final settings = Hive.box<ExperimentalFeaturesModel>(
            _experimentalBox,
          ).get('settings');
          if (settings != null) settingsData['experimental'] = settings.toMap();
        }
        if (Hive.isBoxOpen(_contentBox)) {
          final settings = Hive.box<ContentSettingsModel>(
            _contentBox,
          ).get('settings');
          if (settings != null) settingsData['content'] = settings.toMap();
        }

        backupData['data']['settings'] = settingsData;
      }

      final jsonString = jsonEncode(backupData);
      final fileName =
          'shonenx_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      if (Platform.isAndroid) {
        if (await StorageProvider().requestPermission()) {
          final dir = await StorageProvider().getDefaultDirectory();
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
            final box = Hive.box<ThemeModel>(_themeBox);
            await box.put(
              'settings',
              ThemeModel.fromMap(settingsData['theme']),
            );
          }
          if (settingsData.containsKey('download')) {
            final box = Hive.box<DownloadSettingsModel>(_downloadBox);
            await box.put(
              'settings',
              DownloadSettingsModel.fromMap(settingsData['download']),
            );
          }
          if (settingsData.containsKey('player')) {
            final box = Hive.box<PlayerModel>(_playerBox);
            await box.put(
              'settings',
              PlayerModel.fromMap(settingsData['player']),
            );
          }
          if (settingsData.containsKey('ui')) {
            final box = Hive.box<UiSettings>(_uiBox);
            await box.put('settings', UiSettings.fromMap(settingsData['ui']));
          }
          if (settingsData.containsKey('experimental')) {
            final box = Hive.box<ExperimentalFeaturesModel>(_experimentalBox);
            await box.put(
              'settings',
              ExperimentalFeaturesModel.fromMap(settingsData['experimental']),
            );
          }
          if (settingsData.containsKey('content')) {
            final box = Hive.box<ContentSettingsModel>(_contentBox);
            await box.put(
              'settings',
              ContentSettingsModel.fromMap(settingsData['content']),
            );
          }
        }
      }
    } catch (e, s) {
      AppLogger.e('Failed to import data', e, s);
      rethrow;
    }
  }
}
