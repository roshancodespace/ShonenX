import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

final selectedProviderKeyProvider =
    StateNotifierProvider<SelectedProviderNotifier, SelectedProviderState>(
  (ref) => SelectedProviderNotifier(),
);

class SelectedProviderState {
  final String selectedProviderKey;
  final bool isLoading;

  SelectedProviderState({
    required this.selectedProviderKey,
    this.isLoading = true,
  });
}

class SelectedProviderNotifier extends StateNotifier<SelectedProviderState> {
  final SettingsBox _settingsBox = SettingsBox(); // Keep a single instance

  SelectedProviderNotifier()
      : super(SelectedProviderState(selectedProviderKey: 'hianime')) {
    _init(); // Ensure Hive is initialized before calling load
  }

  Future<void> _init() async {
    await _settingsBox.init(); // Ensure Hive is initialized
    _loadSelectedProvider();
  }

  Future<void> _loadSelectedProvider() async {
    // Try to read the settings
    var settingsModel = _settingsBox.getSettings();

    // Log the current saved provider (likely null on first run)
    log(
        'Before saving, provider: ${settingsModel?.providerSettings?.selectedProviderName}');

    // If no settings exist, create and save the default settings, then re-read them
    if (settingsModel == null) {
      // log("No settings found, creating default settings.");
      // final newSettings = SettingsModel(
      //   providerSettings:
      //       ProviderSettingsModel(selectedProviderName: 'hianime'),
      // );
      // await _settingsBox.saveSettings(newSettings);
      // // Re-read the settings from the box after saving
      // settingsModel = _settingsBox.getSettings();
    }

    // Now extract the provider key (will be 'hianime' by default if still null)
    final selectedProviderKey =
        settingsModel?.providerSettings?.selectedProviderName ?? 'hianime';

    log("Loaded Provider from Hive: $selectedProviderKey");

    state = SelectedProviderState(
      selectedProviderKey: selectedProviderKey,
      isLoading: false,
    );
  }

  Future<void> updateSelectedProvider(String newProvider) async {
    await _settingsBox.updateProviderSettings(
      ProviderSettingsModel(selectedProviderName: newProvider),
    );
    state = SelectedProviderState(
      selectedProviderKey: newProvider,
      isLoading: false,
    );
  }
}
