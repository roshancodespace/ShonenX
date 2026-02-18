import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/core/models/settings/download_settings_model.dart';
import 'package:shonenx/main.dart';

final downloadSettingsProvider =
    NotifierProvider<DownloadSettingsNotifier, DownloadSettingsModel>(
      DownloadSettingsNotifier.new,
    );

class DownloadSettingsNotifier extends Notifier<DownloadSettingsModel> {
  static const _boxName = 'download_settings';
  static const _hiveKey = 'settings';
  static const _prefsKey = 'download_settings_data';

  @override
  DownloadSettingsModel build() {
    final jsonString = sharedPrefs.getString(_prefsKey);
    if (jsonString != null) {
      return DownloadSettingsModel.fromJson(jsonString);
    }
    if (Hive.isBoxOpen(_boxName)) {
      try {
        final box = Hive.box<DownloadSettingsModel>(_boxName);
        final oldSettings = box.get(_hiveKey);
        if (oldSettings != null) {
          sharedPrefs.setString(_prefsKey, oldSettings.toJson());
          return oldSettings;
        }
      } catch (_) {}
    }

    return DownloadSettingsModel();
  }

  void updateSettings(
    DownloadSettingsModel Function(DownloadSettingsModel) updater,
  ) {
    state = updater(state);
    sharedPrefs.setString(_prefsKey, state.toJson());
  }

  void setCustomPath(String? path) {
    updateSettings((s) => s.copyWith(customDownloadPath: path));
  }

  void toggleUseCustomPath(bool use) {
    updateSettings((s) => s.copyWith(useCustomPath: use));
  }

  void setFolderStructure(String structure) {
    updateSettings((s) => s.copyWith(folderStructure: structure));
  }

  void setParallelDownloads(int limit) {
    updateSettings(
      (s) => s.copyWith(parallelDownloads: limit.clamp(1, 100).toInt()),
    );
  }

  void setSpeedLimit(int limitKBps) {
    updateSettings(
      (s) => s.copyWith(speedLimitKBps: limitKBps < 0 ? 0 : limitKBps),
    );
  }

  void toggleWifiOnly(bool wifiOnly) {
    updateSettings((s) => s.copyWith(wifiOnly: wifiOnly));
  }
}
