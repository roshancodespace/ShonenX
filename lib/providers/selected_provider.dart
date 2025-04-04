import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

// Define the provider
final selectedProviderKeyProvider =
    StateNotifierProvider<SelectedProviderNotifier, SelectedProviderState>(
  (ref) => SelectedProviderNotifier(),
);

// State class
class SelectedProviderState {
  final String selectedProviderKey;
  final String? customApiUrl;
  final bool isLoading;
  final String? error;

  SelectedProviderState({
    required this.selectedProviderKey,
    this.customApiUrl,
    this.isLoading = true,
    this.error,
  });

  SelectedProviderState copyWith({
    String? selectedProviderKey,
    String? customApiUrl,
    bool? isLoading,
    String? error,
  }) {
    return SelectedProviderState(
      selectedProviderKey: selectedProviderKey ?? this.selectedProviderKey,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier class
class SelectedProviderNotifier extends StateNotifier<SelectedProviderState> {
  static const String defaultProviderKey = 'hianime';
  final SettingsBox _settingsBox;

  SelectedProviderNotifier()
      : _settingsBox = SettingsBox(),
        super(SelectedProviderState(selectedProviderKey: defaultProviderKey)) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Ensure Hive is initialized
      await _settingsBox.init();
      await _loadSelectedProvider();
    } catch (e, stackTrace) {
      log('Error during initialization: $e', stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize settings: $e',
      );
    }
  }

  Future<void> _loadSelectedProvider() async {
    try {
      // Get settings from Hive
      var settingsModel = _settingsBox.getSettings();
      await _settingsBox.init();

      // If no settings exist, create and save default settings
      if (settingsModel == null) {
        log('No settings found, creating default settings.');
        await _settingsBox.updateProviderSettings(ProviderSettingsModel(
            selectedProviderName: defaultProviderKey, customApiUrl: null));
      }

      // Extract the provider key, falling back to default if null
      final selectedProviderKey =
          settingsModel?.providerSettings.selectedProviderName ??
              defaultProviderKey;
      final customApiUrl = settingsModel?.providerSettings.customApiUrl;

      log('Loaded Provider from Hive: $selectedProviderKey');

      state = state.copyWith(
        selectedProviderKey: selectedProviderKey,
        customApiUrl: customApiUrl,
        isLoading: false,
        error: null,
      );
    } catch (e, stackTrace) {
      log('Error loading provider: $e', stackTrace: stackTrace);
      state = state.copyWith(
        selectedProviderKey: defaultProviderKey,
        isLoading: false,
        error: 'Failed to load provider: $e',
      );
    }
  }

  Future<void> updateSelectedProvider(
      String newProvider, String? apiUrl) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _settingsBox.updateProviderSettings(
        ProviderSettingsModel(
            selectedProviderName: newProvider, customApiUrl: apiUrl),
      );
      state = state.copyWith(
        selectedProviderKey: newProvider,
        customApiUrl: apiUrl,
        isLoading: false,
        error: null,
      );
      log('Updated Provider to: $newProvider');
    } catch (e, stackTrace) {
      log('Error updating provider: $e', stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update provider: $e',
      );
    }
  }
}
