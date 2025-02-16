import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

final appearanceProvider =
    StateNotifierProvider<AppearanceStateNotifier, AppearanceState>((ref) {
  return AppearanceStateNotifier();
});

class AppearanceState {
  final AppearanceSettingsModel? appearanceSettings;
  final bool isLoading;

  AppearanceState({
    this.appearanceSettings,
    this.isLoading = false,
  });
}

class AppearanceStateNotifier extends StateNotifier<AppearanceState> {
  final SettingsBox _settingsBox = SettingsBox(); // Keep a single instance

  AppearanceStateNotifier() : super(AppearanceState()) {
    _init(); // Ensure Hive is initialized before calling load
  }

  Future<void> _init() async {
    await _settingsBox.init();
    _loadAppearanceSettings();
  }

  Future<void> _loadAppearanceSettings() async {
    final appearanceSettings = _settingsBox.getSettings()?.appearanceSettings;
    if (appearanceSettings == null) {
      state = AppearanceState(
        isLoading: false,
        appearanceSettings: AppearanceSettingsModel(themeMode: 'system'),
      );
    } else {
      state = AppearanceState(
        isLoading: false,
        appearanceSettings: appearanceSettings,
      );
    }
  }

  Future<void> updateAppearance(
      AppearanceSettingsModel newAppearanceSettings) async {
    await _settingsBox.updateAppearanceSettings(newAppearanceSettings);
    state = AppearanceState(
      isLoading: true,
      appearanceSettings: newAppearanceSettings,
    );
  }
}
