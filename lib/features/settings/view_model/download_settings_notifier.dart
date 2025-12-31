import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/features/settings/model/download_settings_model.dart';

final downloadSettingsProvider =
    NotifierProvider<DownloadSettingsNotifier, DownloadSettingsModel>(
  DownloadSettingsNotifier.new,
);

class DownloadSettingsNotifier extends Notifier<DownloadSettingsModel> {
  static const _boxName = 'download_settings';
  static const _key = 'settings';

  @override
  DownloadSettingsModel build() {
    if (!Hive.isBoxOpen(_boxName)) {
      return DownloadSettingsModel();
    }
    final box = Hive.box<DownloadSettingsModel>(_boxName);
    return box.get(_key, defaultValue: DownloadSettingsModel()) ??
        DownloadSettingsModel();
  }

  void updateSettings(
      DownloadSettingsModel Function(DownloadSettingsModel) updater) {
    if (!Hive.isBoxOpen(_boxName)) return;
    state = updater(state);
    Hive.box<DownloadSettingsModel>(_boxName).put(_key, state);
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
        (s) => s.copyWith(parallelDownloads: limit.clamp(1, 100).toInt()));
  }

  void setSpeedLimit(int limitKBps) {
    updateSettings(
        (s) => s.copyWith(speedLimitKBps: limitKBps < 0 ? 0 : limitKBps));
  }

  void toggleWifiOnly(bool wifiOnly) {
    updateSettings((s) => s.copyWith(wifiOnly: wifiOnly));
  }
}
